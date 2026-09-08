const name = 'Data Mining and Business Intelligence (DMBI)';
const words = name.split(' ');
const res = words.map((word, idx) => {
  const lowerWord = word.toLowerCase();
  if (idx > 0 && idx < words.length - 1 && ['and', 'or', 'for', 'in', 'of', 'to', 'with', 'a', 'an', 'the'].includes(lowerWord)) return lowerWord;
  return word[0].toUpperCase() + word.substring(1).toLowerCase();
}).join(' ');
console.log(res);
