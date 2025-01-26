# http-glb-host-game-project

The V-Sekai development community focuses on providing social VR functionality for the open-source Godot Engine.

## Quick start

This starts a Godot Engine web server that exports the editor scene as a gltf2 binary.

Tested with [https://github.com/V-Sekai/world-godot/releases/tag/latest.v-sekai-editor-153](https://github.com/V-Sekai/world-godot/releases/tag/latest.v-sekai-editor-153).

`latest.v-sekai-editor-153` implements the DDS image writer `?compatible` flag to stream to VRChat.

It is recommended that you have fast internet and use https://tailscale.com/kb/1223/funnel for proxying the local network to the internet with transport security.

```bash
tailscale funnel 8080
# Start godot editor opened to this project
```

## Test world

You can test the [vr-voyage/vrchat-glb-loader](https://github.com/vr-voyage/vrchat-glb-loader) in the following world :

https://vrchat.com/home/launch?worldId=wrld_a74abb7d-a423-44bb-a7ea-3bc5e8281dde
