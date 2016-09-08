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

Deploying an artifact built by Maven

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
      version_file: version/number
  - put: version
    params: { file: version/number }
```

## Behavior

### `check`: ...

Check not implemented yet...


### `in`: ...

In not implemented yet...


### `out`: Deploy to a repository.

Deploy the artifact to the Maven Repository Manager.

#### Parameters

* `file`: *Required.* The path to the artifact to deploy.

* `version_file`: *Required.* The path to the version file
