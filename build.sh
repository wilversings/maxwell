mkdir -p build

version=$(jq -r '.KPlugin.Version' metadata.json)

tar cfJ "build/maxwell-$version.tar.xz" contents/ metadata.json
