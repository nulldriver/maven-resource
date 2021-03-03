# Maven Resource

[![CI Builds](https://ci.nulldriver.com/api/v1/teams/resources/pipelines/maven-resource/jobs/test/badge)](https://ci.nulldriver.com/teams/resources/pipelines/maven-resource)
[![Docker Pulls](https://img.shields.io/docker/pulls/nulldriver/maven-resource.svg)](https://hub.docker.com/r/nulldriver/maven-resource/)

Deploys and retrieve artifacts from a Maven Repository Manager.



## Source Configuration

* `url`: *Required.* The location of the repository.

* `snapshot_url`: *Optional.* The location of the snapshot repository.

* `artifact`: *Required.* The artifact coordinates in the form of _groupId:artifactId:type[:classifier]_

* `version`: *Optional.* A regular expression matching the entire version of an artifact. If specified only versions matching the regex will be considered. For example `1\.\0\.0-.*` would match all version like `1.0.0-build.123` but not `1.0.0` or `21.0.0-build.123`. Can be used to pin to latest of a major or minor release without bumping to the absolute latest release.

* `username`: *Optional.* Username for accessing an authenticated repository.

* `password`: *Optional.* Password for accessing an authenticated repository.

* `disable_redeploy`: *Optional.* If set to `true`, will not re-deploy a release if the artifact version has been previously deployed. NOTE: has no effect for -SNAPSHOT versions or `snapshot_url`.

* `skip_cert_check`: *Optional.* If set to `true`, will ignore all certificate errors when accessing an SSL repository. NOTE: this will supersede the `repository_cert` configuration if also specified.

* `repository_cert`: *Optional.* CA/server certificate to use when accessing an SSL repository.
    Example:
    ```
    repository_cert: |
      -----BEGIN CERTIFICATE-----
      MIIEowIBAAKCAQEAtCS10/f7W7lkQaSgD/mVeaSOvSF9ql4hf/zfMwfVGgHWjj+W
      <Lots more text>
      DWiJL+OFeg9kawcUL6hQ8JeXPhlImG6RTUffma9+iGQyyBMCGd1l
      -----END CERTIFICATE-----
    ```


## Behavior

### `check`: Check for new versions of the artifact.

Checks for new versions of the artifact by retrieving the `maven-metadata.xml` from
the repository.


### `in`: Fetch an artifact from a repository.

Download the artifact from the repository.

### Files

 * (artifact): Named artifact file.

 * version: File containing the version of the artifact.

### `out`: Deploy artifact to a repository.

Deploy the artifact to the Maven Repository Manager.

#### Parameters

* `file`: *Required.* The path to the artifact to deploy.

* `pom_file`: *Recommended.* The path to the pom.xml to deploy with the artifact.

* `version_file`: *Required.* The path to the version file

## Examples

Resource configuration for an authenticated repository using a custom cert:

``` yaml
resource_types:
- name: maven-resource
  type: registry-image
  source:
    repository: nulldriver/maven-resource
    tag: latest

resources:
- name: artifact
  type: maven-resource
  source:
    url: https://myrepo.example.com/repository/maven-releases/
    snapshot_url: https://myrepo.example.com/repository/maven-snapshots/
    artifact: com.example:example-webapp:jar
    username: myuser
    password: mypass
    repository_cert: |
      -----BEGIN CERTIFICATE-----
      MIIEowIBAAKCAQEAtCS10/f7W7lkQaSgD/mVeaSOvSF9ql4hf/zfMwfVGgHWjj+W
      <Lots more text>
      DWiJL+OFeg9kawcUL6hQ8JeXPhlImG6RTUffma9+iGQyyBMCGd1l
      -----END CERTIFICATE-----
```

Build and deploy an artifact to a Maven Repository Manager:

``` yaml
jobs:
- name: build
  plan:
  - get: source-code
    trigger: true
  - task: build-artifact
    file: source-code/ci/build.yml
  - put: artifact
    params:
      file: task-output/example-webapp-*.jar
      pom_file: source-code/pom.xml
```

Retrieve an artifact and push to Cloud Foundry using [cf-resource](https://github.com/concourse/cf-resource)

``` yaml
jobs:
- name: deploy
  plan:
  - get: source-code
  - get: artifact
    trigger: true
  - put: cf
    params:
      manifest: source-code/manifest.yml
      path: artifact/example-webapp-*.jar
```
