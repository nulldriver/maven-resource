# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 1.3.5 - 2018-03-20
### Fixed
- Interacting with an SSL protected Maven Repository Manager broke with Concourse 3.9.0. The way Concourse now mounts the worker's certificate directory to `/etc/ssl/certs` clobbers the `/etc/ssl/certs/java/cacerts` file placed there by the base [openjdk](https://hub.docker.com/_/openjdk/) image, which is symlinked to at `$JAVA_HOME/jre/lib/security/cacerts`, which of course is needed by Java for SSL stuff.

  So... as a workaround we unlink the link and copy the file directly to `$JAVA_HOME/jre/lib/security/cacerts`. Thx to [@elgohr](https://github.com/elgohr) for working with me on this!

### Changed
- Bumped base [openjdk](https://hub.docker.com/_/openjdk/) image to version `8u151` (from `8u131`).

## 1.3.4 - 2017-10-03
### Fixed
- v1.3.3 introduced [Incorrect SNAPSHOT version checking logic](https://github.com/patrickcrocker/maven-resource/issues/12) for the `check` operation for snapshots but was quickly spotted by [@shinmyung0](https://github.com/shinmyung0). This is now fixed and the 1.3.3 release has been yanked!

### Removed
- Version 1.3.3 (use 1.3.4 instead!!)

## 1.3.3 - 2017-10-03 [YANKED]
### Added
- Change log file (CHANGELOG.md).
- Generate release notes from CHANGELOG.me for github release (pipeline.yml).

### Changed
- Updated examples to better show `cf push` with filename glob (README.md).
- Move `apt-get clean` and tmp folder deletion to `apt-get install` block (Dockerfile).
- Pin parent docker image version `openjdk:8u131-jdk-alpine` (Dockerfile) and `openjdk:8u131-jdk` (debian/Dockerfile).
- Use Maven 3.5.0 (maven-wrapper.properties).
- Move test & itest folders into /opt/resource folder in image to facilitate easier itest runs while in a running container (Dockerfile, debian/Dockerfile).
-

### Fixed
- `check` operation no longer silently fails on ssl cert errors.
- `get` and `put` scripts now use the existing java keystore as a base for adding custom ssl certs.

## 1.3.2 - 2017-05-22

## 1.3.1 - 2017-03-31
