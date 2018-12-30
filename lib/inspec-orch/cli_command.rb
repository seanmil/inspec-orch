# encoding: utf-8

require 'inspec/resource'
require 'orchestrator_client'
require 'tempfile'
require 'uri'

module InspecPlugins::Orch
  class CliCommand < Inspec.plugin(2, :cli_command)
    subcommand_desc 'orch [COMMAND]', 'Run InSpec using the Puppet Enterprise Orchestrator.'

    def self.target_options
      option :target, aliases: :t, type: :string,
        desc: 'Specify PCP target using URIs, e.g. pcp://certname'
      option :certname, type: :string,
        desc: 'Specify PCP target using plain certname.'
      option :orch_host, type: :string,
        desc: 'PE Orchestrator hostname to connect to.'
      option :orch_port, type: :string,
        desc: 'PE Orchestrator port to connect to.'
      option :environment, type: :string,
        desc: 'PE environment to run Tasks against.'
      option :cacert, type: :string,
        desc: 'Path to the Puppet Enterprise CA certificate.'
      option :token_file, type: :string,
        desc: 'Path to a valid Puppet Enterprise RBAC token file.'
    end

    desc 'detect [OPTIONS]', 'Detect the target OS.'
    target_options
    option :format, type: :string
    def detect
      o = opts(:detect).dup
      o[:backend] = 'pcp'

      run_plan(:detect, o, host(o), "InSpec detect run on #{host(o)}") do |plan_job|
        o[:plan_job] = plan_job
        o[:command] = 'platform.params'
        (_, res) = run_command(o)
        res
      end

      if o['format'] == 'json'
        puts res.to_json
      else
        headline('Platform Details')
        puts Inspec::BaseCLI.detect(params: res, indent: 0, color: 36)
      end
    end

    desc 'exec LOCATIONS', 'run all test files at the specified LOCATIONS.'
    exec_options
    def exec(*targets)
      o = opts(:exec).dup

      diagnose(o)
      configure_logger(o)

      o[:backend] = 'pcp'

      run_plan(:exec, o, host(o), "InSpec exec run for one or more profiles on #{host(o)}") do |plan_job|
        o[:plan_job] = plan_job
        reporters = o[:reporter]

        display_json = false

        # Setup the JSON reporter
        reporters['json'] = { 'stdout' => false } unless reporters['json']

        if reporters['json']['stdout'] == true
          # Save this in case we are supposed to also display JSON:
          display_json = true
          reporters['json']['stdout'] = false
        end

        # If the user specified a path then use it, otherwise generate a tempfile:
        if reporters['json']['file']
          outfile = reporters['json']['file']
          tmpfile = nil
        else
          tmpfile = Tempfile.new(['inspec-orch','.json'])
          outfile = tmpfile.path
          reporters['json']['file'] = outfile
        end

        runner = Inspec::Runner.new(o)
        targets.each { |target| runner.add_target(target) }

        runner.run

        result_data = File.read(outfile)
        tmpfile.unlink if tmpfile

        results = JSON.parse(result_data)

        puts result_data if display_json
        results
      end
    end

    private

    def orch_uri(o)
      if o[:orch_host]
        uri = URI('https://')
        uri.host = o[:orch_host]
        uri.port = o[:orch_port]
        uri.to_s
      else
        nil
      end
    end

    def orch_client(o)
      opts = {}
      opts['service-url'] = orch_uri(o) unless orch_uri(o).nil?
      opts['cacert'] = o[:cacert] unless o[:cacert].nil?
      opts['token-file'] = o[:token_file] unless o[:token_file].nil?

      OrchestratorClient.new(opts, load_files: true)
    end

    def host(o)
      URI.parse(o[:target]).hostname
    end

    def run_plan(type, opts, node, desc, &block)
      client = orch_client(opts)

      job = plan_start(client, type, opts)

      results = begin
                  {
                    status: "success",
                    result: block.call(job),
                  }
                rescue => e
                  {
                    status: "failure",
                    result: {
                      error: {
                        exception_class: e.class,
                        exception_message: e.message,
                        backtrace: e.backtrace,
                      },
                    },
                  }
                end

      plan_finish(client, job, results)
    end

    def plan_start(orch, type, opts)
      req = {
        plan_name: "inspec::#{type}",
        description: "InSpec #{type} execution for node #{host(opts)}",
        params: {},
      }
      resp = orch.command.plan_start(req)
      resp['name']
    end

    def plan_finish(orch, plan_job, result)
      req = {
        plan_job: plan_job,
      }.merge(result)
      orch.command.plan_finish(req)
    end

    def run_command(opts)
      runner = Inspec::Runner.new(opts)
      res = runner.eval_with_virtual_profile(opts[:command])
      runner.load

      return :ruby_eval, res if runner.all_rules.empty?
      return :rspec_run, runner.run_tests # rubocop:disable Style/RedundantReturn
    end
  end
end
