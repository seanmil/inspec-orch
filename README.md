# InSpec Plugin - inspec-orch

This InSpec plugin adds a new command to the InSpec CLI interface which
uses the Puppet Enterprise Orchestrator for both communications transport
and results of an InSpec run. This allows InSpec to be used where the
Puppet Enterprise pxp-agent is working but SSH/WinRM might be problematic.

This plugin requires the train-pcp plugin, which enables use of the
PCP transport found in Puppet Enterprise.

## Installation

You will need InSpec v2.3 or later.

For the latest released inspec-orch plugin:
```
$ inspec plugin install inspec-orch
```

To test the latest master branches of inspec-orch and/or train-pcp
add this to the `Gemfile` from which InSpec is installed:

```ruby
gem 'inspec-orch', git: 'https://github.com/seanmil/inspec-orch'
gem 'train-pcp', git: 'https://github.com/seanmil/train-pcp'
```

Additionally, if you are installing this plugin manually (not using
`inspec plugin install`) then you will need to configure the plugin
in the `~/.inspec/plugins.json` file:
```json
{
  "plugins_config_version": "1.0.0",
  "plugins": [
    {
      "name": "inspec-orch",
      "installation_type": "path",
      "installation_path": "/path/to/cloneof/inspec-orch/lib/inspec-orch"
    }
  ]
}
```

You can also override the location that InSpec looks for the `plugins.json` file
with `INSPEC_CONFIG_DIR`. See [the plugins.json file](https://github.com/inspec/inspec/blob/master/docs/dev/plugins.md#the-pluginsjson-file)

## Usage

To use this plugin you will need:
- A working Puppet Enterprise installation (>= 2017.x)
- A system with the PE client-tools installed and correctly configured (e.g. "puppet task" should work)
- A valid PE RBAC token (saved to (~/.puppetlabs/token)

Additionally you will need the following requirements from train-pcp:
- Rights to run the following PE Tasks:
  - bolt\_spec::shim from [puppetlabs/bolt_shim](https://forge.puppet.com/puppetlabs/bolt_shim)

You can then run:

```
$ inspec orch exec mytest.rb -t pcp://<certname>
```

All of the executed tasks should appear under a single Plan in the PE Console and
the results of the run should not only go to the normal reporter location(s) specified
but also to the Plan results.

## Limitations

This plugin is primarily under the same limitations as listed in the train-pcp plugin.
Namely, that issuing commands via the PE Orchestrator will not be as fast as over an
established SSH/WinRM connection.

Additionally, the reporter mechanism in InSpec doesn't expose a plugin system so
this plugin has a fair amount of additional complication to enable the results
to be sent to the Plan results while still preserving the normal user-selectable
reporter behavior. Hopefully this doesn't end up causing any unforeseen problems.
