# sig-mirror Tool

The `sig-mirror` tool is a utility script for mirroring, caching self-signing all the container-base-images from the Red Hat Operator Catalog to a Air Gap environment

## Maintainer

[Mihai IDU](mailto:midu@redhat.com)

## License

This project is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Usage

Before using the `sig-mirror` tool, make sure to configure the necessary parameters in the `config.yaml` file.

## Configuration

Edit the `config.yaml` file to set the following parameters:

- ocp_release_version: OpenShift Container Platform release version.
- redhat_operator_index_version: Red Hat Operator Index version.
- release_number: Release number for identification.
- registry_fqdn: Fully qualified domain name of the cache registry.
- registry_port: Port number of the cache registry.
- operator_list: List of operators to mirror.

## Dependencies

The following dependencies are required to run the `sig-mirror` tool:

- yq: YAML processor.
- skopeo
- oc
- oc-mirror


## Installation

Before running the `sig-mirror` tool, ensure that the required dependencies are installed. You can use the provided dependencies_checker function to automatically download and configure the dependencies.

```bash
./sig-mirror.sh dependencies_checker
```

## Contributing

Feel free to contribute by submitting bug reports, feature requests, or pull requests.

```bash
Make sure to replace "Your Name" and "your@email.com" with your actual name and email address. Additionally, update the "Usage," "Configuration," and "Mirroring" sections based on the specific instructions for your tool.

Please note that the provided template assumes that the `dependencies_checker` and `mirroring_to_cache_registry` functions are part of the script and that the `yq` dependency is necessary. Adjust the README accordingly if there are additional or different dependencies.
```
