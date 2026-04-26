/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#5C4A8F',
          hover: '#7B61B5',
          light: '#EDE9F7',
        },
        background: '#FAFAF8',
        surface: '#FFFFFF',
        'surface-alt': '#F4F3EF',
        border: '#E5E3DE',
        text: {
          primary: '#1C1917',
          secondary: '#57534E',
          tertiary: '#A8A29E',
        },
        destructive: '#B85C6A',
      },
      fontFamily: {
        sans: ['DM Sans', 'sans-serif'],
        heading: ['Lora', 'serif'],
        mono: ['DM Mono', 'monospace'],
      },
      screens: {
        sm: '640px',
        md: '768px',
        lg: '1024px',
        xl: '1280px',
        '2xl': '1536px',
      },
      animation: {
        'fade-in': 'fadeIn 0.2s ease-out',
        'slide-up': 'slideUp 0.2s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(100%)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
