# Roku SDK Development

## Updating Version

To update the SDK version:

1. Modify the `VERSION` constant in `code/main/common/version.brs`
2. Update any related documentation

## Release Steps

The Roku SDK and the sample app will be released together. The sample app showcases the use of the Roku SDK in a Roku channel, demonstrating how developers can integrate the SDK into their own applications.

### 1. Build and Package the Roku SDK

The SDK build process involves several key steps:

- **[Optional] `make clean`**: Removes previous build artifacts to ensure a clean build

- **`make build-sdk`**: Merges all source code files into a single `AEPSDK.brs` file.
- **`make archive`**: Creates a complete SDK package (`AEPRokuSDK.zip`) ready for distribution

#### SDK Build Process

The `build-sdk` target runs `./build/build.sh` which:

1. **Creates Output Directory**: Sets up the `./output` directory structure
2. **Copies Components**: Copies all component files to the output directory
3. **Merges Source Code**: Combines all source files into a single `AEPSDK.brs` file
4. **Module Validation**: Ensures each `.brs` file has a proper MODULE declaration
5. **Metadata Generation**: Creates `info.txt` with git hash, version, and MD5 hash

#### SDK Archive Process

The `archive` target:

1. **Cleans Previous Builds**: Removes old output and AEPRokuSDK directories
2. **Builds SDK**: Executes the SDK build process
3. **Validates Output**: Ensures all required files are present
4. **Packages SDK**: Creates `AEPRokuSDK` directory and zips it
5. **Output**: Produces `./out/AEPRokuSDK.zip`

#### SDK Package Contents

- `AEPSDK.brs` - Main SDK file (merged from all source files)
- `components/adobe/` - Task components and XML definitions
- `info.txt` - Build metadata (git hash, version, MD5 hash)

### 2. Integrate SDK with Sample App

The sample app automatically integrates the built SDK:

- **[Optional] `make clean`**: Removes SDK files from the sample app when needed

- **`make install-sdk`**: Extracts the SDK package and installs it into the sample app
- **`make build`**: Compiles the sample app with the integrated SDK

#### Output Structure

```
./out/
└── AEPRokuSDK.zip          # Complete SDK package

./sample/simple-videoplayer-channel/
├── components/
│   └── adobe/              # SDK components
│       ├── AEPSDKTask.brs
│       └── AEPSDKTask.xml
└── source/
    └── AEPSDK.brs          # Main SDK file
```

### 3. Create a GitHub release with the above artifacts

After building the SDK and sample app, create a GitHub release to distribute the artifacts:

1. **Tag the release**: Create a git tag matching the SDK version

2. **Upload artifacts**: Include the following files in your GitHub release:

   - `AEPRokuSDK.zip` - The complete SDK package
   - `simple-videoplayer-channel` - The built sample app showcasing the SDK
   - Release notes documenting new features and changes
