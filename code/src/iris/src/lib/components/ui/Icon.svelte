<script lang="ts">
  import { onMount } from 'svelte';
  import { iconMap, type IconName } from '../../icons';
  
  interface $$Props {
    icon: IconName | string;
    width?: string | number;
    height?: string | number;
    class?: string;
  }
  
  export let icon: IconName | string;
  export let width: string | number = 24;
  export let height: string | number = 24;
  let className: string = '';
  export { className as class };
  
  let svgContent = '';
  let loading = true;
  
  onMount(() => {
    loadIcon();
  });
  
  $: if (icon) {
    loadIcon();
  }
  
  async function loadIcon() {
    loading = true;
    svgContent = '';
    
    try {
      if (icon in iconMap) {
        const module = await iconMap[icon as IconName]();
        svgContent = module.default;
      } else {
        console.warn(`Icon "${icon}" not found in local icon set`);
      }
    } catch (error) {
      console.error(`Failed to load icon "${icon}":`, error);
    } finally {
      loading = false;
    }
  }
  
  function processSvg(svg: string): string {
    // Remove width/height from SVG to make it responsive
    return svg
      .replace(/width="[^"]*"/, '')
      .replace(/height="[^"]*"/, '')
      .replace(/<svg/, `<svg width="${width}" height="${height}"`);
  }
</script>

{#if loading}
  <span 
    class="inline-block {className}" 
    style="width: {width}px; height: {height}px;"
  ></span>
{:else if svgContent}
  <span 
    class="inline-block {className}"
    aria-hidden="true"
  >
    {@html processSvg(svgContent)}
  </span>
{/if}

<style>
  span :global(svg) {
    display: block;
    fill: currentColor;
  }
</style>