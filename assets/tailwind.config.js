module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.eex',
    '../lib/**/*.leex',
    '../lib/**/*.sface',
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
