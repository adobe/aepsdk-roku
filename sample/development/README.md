# About

This Roku channel is built for SDK development.

## Initializing Project

To test with this Roku channel, create a `test_config.json` file under the [source](./source) directory and add the edge configuration as shown below.

```json
{"config_id":"your edge config id"}
```

From the sample/development directory run the following command in a terminal window to link the development app to the SDK:
```
make link-sdk
```

### VSCode plugin

For developers using the [VSCode plugin (BrightScript Language extension for VSCode)](https://marketplace.visualstudio.com/items?itemName=RokuCommunity.brightscript), the `launch.json` under `.vscode` is configued to work with the plugin.

To deploy the Roku channel to your Roku device, you need to provide a `settings.json` file under the `.vscode` directory and add the below information.

```json
{
    "roku_ip": "The IP address of you Roku device",
    "roku_password": "The password for uploading the Roku channel",
}
```
