/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        'apertura': ['Apertura', 'sans-serif'],
      },
      colors: {
        'brand': {
          'primary': '#009bff',
          'secondary': '#12223f',
          'tertiary': '#e7f67e',
        }
      },
      backgroundColor: {
        'brand-primary': '#009bff',
        'brand-secondary': '#12223f',
        'brand-tertiary': '#e7f67e',
      },
      textColor: {
        'brand-primary': '#009bff',
        'brand-secondary': '#12223f',
        'brand-tertiary': '#6b7280',
      },
      borderColor: {
        'brand-primary': '#009bff',
        'brand-secondary': '#12223f',
      },
      fontSize: {
        'xs': ['1rem', { lineHeight: '1.5rem' }],         // 16px (was 12px)
        'sm': ['1.125rem', { lineHeight: '1.75rem' }],    // 18px (was 14px)
        'base': ['1.25rem', { lineHeight: '2rem' }],      // 20px (was 16px)
        'lg': ['1.5rem', { lineHeight: '2.25rem' }],      // 24px (was 18px)
        'xl': ['1.75rem', { lineHeight: '2.5rem' }],      // 28px (was 20px)
        '2xl': ['2rem', { lineHeight: '2.75rem' }],       // 32px (was 24px)
        '3xl': ['2.5rem', { lineHeight: '3rem' }],        // 40px (was 30px)
        '4xl': ['3rem', { lineHeight: '3.5rem' }],        // 48px (was 36px)
        '5xl': ['4rem', { lineHeight: '1' }],             // 64px (was 48px)
        '6xl': ['5rem', { lineHeight: '1' }],             // 80px (was 60px)
      }
    },
  },
  plugins: [],
}