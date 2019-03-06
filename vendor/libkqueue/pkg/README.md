This directory contains native packaging scripts for various platforms.

The Makefile could optionally be converted into a CMakeLists file.

Non-working example:

    add_custom_target(tarball git archive -o "libkqueue-${PROJECT_VERSION}.tar.gz" --prefix "libkqueue-${PROJECT_VERSION}/" HEAD)
    
    add_custom_target(docker_image docker build -t libkqueue-build --build-arg "project_version=${PROJECT_VERSION}" .
            DEPENDS tarball)
            
    add_custom_target(native_package docker run --rm -it libkqueue-deb dpkg-buildpackage -uc -us -sn
            DEPENDS docker_image)
            
    add_custom_target(debug_package_build docker run --rm -it libkqueue-deb docker run --rm -it libkqueue-deb:latest dpkg-buildpackage -uc -us
            DEPENDS docker_image)

