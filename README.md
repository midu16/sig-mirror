# sig-mirror Tool

The `sig-mirror` tool is a utility script for mirroring, caching self-signing all the container-base-images from the Red Hat Operator Catalog to a Air Gap environment



:warning: **`sig-mirror` tool is a community project, it is not supported by Red Hat in any way.** :warning:


## Maintainer

[Mihai IDU](mailto:midu@redhat.com)

[Teresa Giner](mailto:tginer@redhat.com)

## License

This project is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Usage

Before using the `sig-mirror` tool, make sure to configure the necessary parameters in the `config.yaml` file.

## Configuration

Edit the `config.yaml` file to set the following parameters:

- ocp_release_version: Mandatory : OpenShift Container Platform release version.
- redhat_operator_index_version: Mandatory : Red Hat Operator Index version.
- release_number: Mandatory : Release number for identification.
- registry_fqdn: Mandatory : Fully qualified domain name of the cache registry.
- registry_port: Mandatory : Port number of the cache registry.
- operator_list: Mandatory : List of operators to mirror.
- signer_email: Optional : `gpg` email-ID configured on the host for self-sign.
- path_signer_pub_key: Mandatory : Path to the signer-key.pub.
- path_signer_passphrase: Mandatory : Path to the signer-passphrase used. Empty if no passphrase its being used.

## Dependencies

The following dependencies are required to run the `sig-mirror` tool:

- yq: YAML processor.
- skopeo: Command line utility used to interact with local and remote container images and container image registries
- oc: OpenShift Client
    - oc-mirror: OpenShift Client plugin used for mirroring 
- gpg: OpenPGP encryption and signing tool
- `Cache-Registry` certificates are known to the `sig-mirror` host
- `config.yaml.example` represints an example config file. The expected config file name its: `config.yaml`
- Make sure that the `${HOME}/.docker/config.json` its made available with the right pull-secret to access the `Cache-Registry`
- Make sure that the following configuration for the `Cache-Registry` its made available:

:warning: **Make sure that the `rock5b.offline.oxtechnix.lan:5000` are replaced with the values from your environment** :warning:

   - Adding the `Cache-Registry` public signatures in `/etc/containers/policy.json`:

```bash
$ cat /etc/containers/policy.json
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker": {
	    "registry.access.redhat.com": [
		{
		    "type": "signedBy",
		    "keyType": "GPGKeys",
		    "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
		}
	    ],
	    "registry.redhat.io": [
		{
		    "type": "signedBy",
		    "keyType": "GPGKeys",
		    "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
		}
	    ],
	    "rock5b.offline.oxtechnix.lan:5000/signed": [
		{
		    "type": "sigstoreSigned",
		    "keyPath": "/etc/pki/rpm-gpg/signer-key.pub"
		 }
        ]
	},
        "docker-daemon": {
	    "": [
		{
		    "type": "insecureAcceptAnything"
		}
	    ]
	}
    }
}
```

   - Adding the `Cache-Registry` definition in `/etc/containers/registries.d/rock5b.offline.oxtechnix.lan.yaml`:

```bash
$ cat /etc/containers/registries.d/rock5b.offline.oxtechnix.lan.yaml 
docker:
     rock5b.offline.oxtechnix.lan:5000:
       use-sigstore-attachments: true

```

## Installation

Before running the `sig-mirror` tool, ensure that the required dependencies are installed. You can use the provided function to automatically download and configure the binary dependencies.

```bash
$ ./sig-mirror
Interactive CLI Interface
==========================
Enter an option (h for help, q to quit): h
Usage: ./test_script.sh [OPTION]
sig-mirror Interactive CLI Interface

Options:
  -h, --help      Display this help menu
  -a, --dependency-check  Perform an dependency check of your environment. Make sure that binary dependencies are made available.
  -b, --air-gap-bundle    Perform an Air-Gap Bundle Release Creation.
  -c, --air-gap-mirror    Perform an Air-Gap Bundle Release Mirror to Offline Registry.TBD
Enter an option (h for help, q to quit): --dependency-check
Perform an dependency check of your environment
Supported operating system: fedora
Operating system validation passed.
All dependencies are installed.
/home/midu/sig-script/sig-work-dir/dependencies/yq exists.
/home/midu/sig-script/sig-work-dir/dependencies/cosign exists.
YAML file validation passed.
Enter an option (h for help, q to quit): q
Exiting...
```

## Contributing

Feel free to contribute by submitting bug reports, feature requests, or pull requests.

```bash
Make sure to replace "Your Name" and "your@email.com" with your actual name and email address. Additionally, update the "Usage," "Configuration," and "Mirroring" sections based on the specific instructions for your tool.

Please note that the provided template assumes that the `dependencies_checker` and `mirroring_to_cache_registry` functions are part of the script and that the `yq` dependency is necessary. Adjust the README accordingly if there are additional or different dependencies.
```
## References

[1] https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/building_running_and_managing_containers/assembly_signing-container-images_building-running-and-managing-containers