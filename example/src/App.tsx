import { Text, View, StyleSheet } from 'react-native';
import { performOTACheck } from 'bundlepush';
import { useEffect } from 'react';

export default function App() {
  useEffect(() => {
    performOTACheck();
  }, []);

  return (
    <View style={styles.container}>
      <Text>Hello World</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
