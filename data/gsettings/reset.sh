# Resets Kumiko settings to default for testing purposes
gsettings list-schemas | grep kumiko | xargs -n 1 gsettings reset-recursively
dconf list /io/github/iqzer0/kumiko/profiles/ | xargs -I {} dconf reset -f "/io/github/iqzer0/kumiko/profiles/"{}
