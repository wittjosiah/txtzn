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
        peach: {
          600: '#FFD485',
          500: '#FFDB99',
          400: '#FFE2AD',
          300: '#FFEAC2',
          200: '#FFF1D6',
          100: '#FFF8EB'
        },
        moss: {
          600: '#87B569',
          500: '#A8C992',
          400: '#B3D09F',
          300: '#C1D9B1',
          200: '#d3e4c8',
          100: '#DEEBD6'
        }
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
