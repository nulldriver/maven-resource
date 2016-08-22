# Maven Resource

Deploys and retrieve artifacts from a Maven Repository Manager.


## Source Configuration

* `url`: *Required.* The location of the repository.

* `username`: *Optional.* Username for HTTP(S) auth when accessing an authenticated repository.
  This is needed when only HTTP/HTTPS protocol for git is available (which does not support private key auth)
  and auth is required.

* `password`: *Optional.* Password for HTTP(S) auth when accessing an authenticated repository.

* `repository_cert`: *Optional.* CA/server certificate to use when accessing a repository.
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
    username: myuser
    password: mypass
    repository_cert: |
      -----BEGIN CERTIFICATE-----
      MIIEowIBAAKCAQEAtCS10/f7W7lkQaSgD/mVeaSOvSF9ql4hf/zfMwfVGgHWjj+W
      <Lots more text>
      DWiJL+OFeg9kawcUL6hQ8JeXPhlImG6RTUffma9+iGQyyBMCGd1l
      -----END CERTIFICATE-----
```

Deploying an artifact build by Maven

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
      groupId: com.mygroup
      artifactId: myartifact
      packaging: jar
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

* `groupId`: *Required.* The groupId of the artifact

* `artifactId`: *Required.* The artifactId of the artifact

* `packaging`: *Required.* The packaging of the artifact
