# http-glb-host-game-project

Welcome to the V-Sekai development community! We provide social VR features for the open-source [Godot Engine](https://godotengine.org/).

## Quick Start

Follow these steps to set up the Godot Engine web server:

1. **Download the Editor:**

   Get the latest editor version from [here](https://github.com/V-Sekai/world-godot/releases/tag/latest.v-sekai-editor-153).

2. **Configure DDS Image Writer:**

   The `latest.v-sekai-editor-153` includes the DDS image writer with the `?compatible` flag for VRChat streaming.

3. **Set Up Network Proxy:**

   Ensure you have a fast internet connection. Use [Tailscale Funnel](https://tailscale.com/kb/1223/funnel) to securely proxy your local network to the internet.

4. **Start the Server:**

   Open your terminal and run:

   ```bash
   tailscale funnel 8080
   # Save the funnel link for sharing
   # Then, open the Godot editor with this project
   ```

## Test the World

Test the [VRChat GLB Loader](https://github.com/vr-voyage/vrchat-glb-loader) in the following world:

[Launch the World](https://vrchat.com/home/launch?worldId=wrld_a74abb7d-a423-44bb-a7ea-3bc5e8281dde)
