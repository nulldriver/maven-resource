# Maven Resource

Deploys and retrieve artifacts from a Maven Repository Manager.



## Source Configuration

* `url`: *Required.* The location of the repository.

* `artifact`: *Required.* The artifact coordinates in the form of _groupId:artifactId:type[:classifier]_

* `username`: *Optional.* Username for accessing an authenticated repository.

* `password`: *Optional.* Password for accessing an authenticated repository.

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


### Example

Resource configuration for an authenticated repository:

``` yaml
resource_types:
- name: maven-resource
  type: docker-image
  source:
    repository: patrickcrocker/maven-resource
    tag: latest

resources:
- name: milestone
  type: maven-resource
  source:
    url: https://myrepo.com/repository/milestones
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

## Behavior

### `check`: Check for new versions of the artifact.

Checks for new versions of the artifact by retrieving the `maven-metadata.xml` from
the repository.


### `in`: Fetch an artifact from a repository.

Download the artifact from the repository.


### `out`: Deploy artifact to a repository.

Deploy the artifact to the Maven Repository Manager.

#### Parameters

* `file`: *Required.* The path to the artifact to deploy.

* `pom_file`: *Recommended.* The path to the pom.xml to deploy with the artifact.

* `version_file`: *Required.* The path to the version file

## Examples

Deploying an artifact built by Maven:

``` yaml
jobs:
- name: build
  plan:
  - get: source-code
    trigger: true
  - get: version
    params: { pre: rc }
  - task: build
    file: source-code/ci/build.yml
  - put: milestone
    params:
      file: build-output/myartifact-*.jar
      pom_file: source-code/pom.xml
      version_file: version/number
  - put: version
    params: { file: version/number }
```

Retrieve a _milestone_ artifact, push to Cloud Foundry and run integration tests:

``` yaml
- name: test
  plan:
  - get: milestone
    trigger: true
    passed: [ build ]
  - get: source-code
    passed: [ build ]
  - get: version
    passed: [ build ]
  - task: prepare-cf
    file: source-code/ci/prepare-cf.yml
  - put: cf
    params:
      manifest: prepare-cf-output/manifest.yml
  - task: integration
    file: source-code/ci/integration-test.yml
    params:
      API_ENDPOINT: https://myapp.cfapps.io/
```
