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
    class="icon-placeholder inline-block {className}" 
    data-width={width}
    data-height={height}
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
  
  /* Dynamic sizing for loading placeholder using data attributes */
  .icon-placeholder[data-width="14"] { width: 14px; }
  .icon-placeholder[data-height="14"] { height: 14px; }
  .icon-placeholder[data-width="16"] { width: 16px; }
  .icon-placeholder[data-height="16"] { height: 16px; }
  .icon-placeholder[data-width="18"] { width: 18px; }
  .icon-placeholder[data-height="18"] { height: 18px; }
  .icon-placeholder[data-width="20"] { width: 20px; }
  .icon-placeholder[data-height="20"] { height: 20px; }
  .icon-placeholder[data-width="24"] { width: 24px; }
  .icon-placeholder[data-height="24"] { height: 24px; }
  .icon-placeholder[data-width="28"] { width: 28px; }
  .icon-placeholder[data-height="28"] { height: 28px; }
  .icon-placeholder[data-width="32"] { width: 32px; }
  .icon-placeholder[data-height="32"] { height: 32px; }
  .icon-placeholder[data-width="48"] { width: 48px; }
  .icon-placeholder[data-height="48"] { height: 48px; }
</style>