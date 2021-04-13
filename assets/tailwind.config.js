module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      colors: {
        paper: '#fffefa',
      },
      screens: {
        'sm': { max: '767px' }
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
