function makeColor(name) {
  return ({ opacityVariable, opacityValue }) => {
    if (opacityValue !== undefined) {
      return `rgba(var(--${name}), ${opacityValue})`
    }
    if (opacityVariable !== undefined) {
      return `rgba(var(--${name}), var(${opacityVariable}, 1))`
    }
    return `rgb(var(--${name}))`
  };
}

module.exports = {
  content: [
    '../terrat_ui_site/*.html',
    '../terrat_ui_js/*.js'
  ],
  theme: {
    extend:{
      screens: {
        '3xl': '1800px'
      },
      colors: {
        // primary: makeColor('color-primary'),
        // secondary: makeColor('color-secondary'),
        // success: makeColor('color-success'),
        // fail: makeColor('color-fail'),
        // heading: makeColor('color-heading'),
        // subheading: makeColor('color-subheading'),
        // action: makeColor('color-action'),
        // danger: makeColor('color-danger'),
        // disabled: makeColor('color-disabled')
      },
      keyframes: {
        'fade-in': {
          '0%': {
            opacity: '0'
          },
          '100%': {
            opacity: '1'
          }
        },
        'gradient': {
          '0%': {
            'background-position': '100% 50%'
          },
          '50%': {
            'background-position': '0% 50%'
          },
          '100%': {
            'background-position': '100% 50%'
          }
        },
        'expand': {
          '50%': {
            'transform': 'scale(1.2)',
            'opacity': '0.75'
          },
          '100%': {
            'transform': 'scale(1)'
          },
        }
      },
      animation: {
        'fade-in': 'fade-in 500ms linear 1',
        'progress-bar': 'gradient 8s linear infinite',
        'ping-5-times': 'ping 1s cubic-bezier(0, 0, 0.2, 1) 5',
        'ping-1-time': 'ping 1s cubic-bezier(0, 0, 0.2, 1) 1',
        'expand': 'expand 1s cubic-bezier(0, 0, 0.2, 1) infinite',
        'expand-1-time': 'expand 1s cubic-bezier(0, 0, 0.2, 1) 1',
      }
    },
  },
  variants: {
    extend: {
      backgroundColor: ['checked'],
      borderColor: ['checked'],
      animation: ['hover']
    }
  },
  plugins: [],
}
