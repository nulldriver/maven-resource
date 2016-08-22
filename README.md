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
      -----BEGIN RSA PRIVATE KEY-----
      MIIEowIBAAKCAQEAtCS10/f7W7lkQaSgD/mVeaSOvSF9ql4hf/zfMwfVGgHWjj+W
      <Lots more text>
      DWiJL+OFeg9kawcUL6hQ8JeXPhlImG6RTUffma9+iGQyyBMCGd1l
      -----END RSA PRIVATE KEY-----
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
      groupId: com.mygroup
      artifactId: myartifact
      version_file: version/number
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

* `pom`: *Optional.* The path to the pom.xml file to use for the `groupId`, `artifactId`, `packaging`, and `version`.

  *Note:* Specifying any of the below `groupId`, `artifactId`, `packaging`, or `version_file` parameters will override the value found in the pom.xml file.

* `version_file`: *Optional.* The path to the version file (*Required.* if not using `pom` file)

* `groupId`: *Optional.* The groupId of the artifact (*Required.* if not using `pom` file)

* `artifactId`: *Optional.* The artifactId of the artifact (*Required.* if not using `pom` file)

* `packaging`: *Optional.* The packaging of the artifact (*Required.* if not using `pom` file)
