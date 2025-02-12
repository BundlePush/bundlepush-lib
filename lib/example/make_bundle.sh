rm -rf generated_bundle

npx react-native bundle \
  --platform ios \
  --dev false \
  --entry-file index.js \
  --bundle-output generated_bundle/main.jsbundle \
  --assets-dest generated_bundle \
  --reset-cache

cd generated_bundle && zip -r bundle.zip * 
