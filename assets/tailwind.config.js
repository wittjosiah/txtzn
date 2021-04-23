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
      height: {
        'screen-1/4': '25vh',
        'screen-1/3': '33vh',
        'screen-1/2': '50vh',
        'screen-3/4': '75vh'
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
