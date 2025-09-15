<script lang="ts">
  export let data: number[] = [];
  export let width: number = 100;
  export let height: number = 30;
  export let highlightThreshold: number = 1;
  export let strokeColor: string = 'currentColor';
  export let fillColor: string = 'none';
  export let className: string = '';
  
  // Calculate the SVG path for the sparkline
  function generatePath(points: number[]): string {
    if (points.length === 0) return '';
    if (points.length === 1) return `M 0,${height} L ${width},${height}`;
    
    const max = Math.max(...points, 1); // Ensure at least 1 to avoid division by zero
    const min = Math.min(...points, 0);
    const range = max - min || 1;
    
    // Calculate x spacing
    const xStep = width / (points.length - 1);
    
    // Generate path points
    const pathPoints = points.map((value, index) => {
      const x = index * xStep;
      const y = height - ((value - min) / range) * height;
      return `${x},${y}`;
    });
    
    // Create smooth curve path
    return `M ${pathPoints.join(' L ')}`;
  }
  
  // Generate highlight zones where values exceed threshold
  function generateHighlightZones(points: number[]): Array<{x: number, width: number}> {
    if (points.length === 0) return [];
    
    const zones: Array<{x: number, width: number}> = [];
    const xStep = width / (points.length - 1);
    
    let inZone = false;
    let zoneStart = 0;
    
    points.forEach((value, index) => {
      const exceeds = value > highlightThreshold;
      const x = index * xStep;
      
      if (exceeds && !inZone) {
        // Start a new zone
        inZone = true;
        zoneStart = x;
      } else if (!exceeds && inZone) {
        // End the current zone
        inZone = false;
        zones.push({
          x: zoneStart,
          width: x - zoneStart
        });
      }
    });
    
    // Close any open zone
    if (inZone) {
      zones.push({
        x: zoneStart,
        width: width - zoneStart
      });
    }
    
    return zones;
  }
  
  $: path = generatePath(data);
  $: highlightZones = generateHighlightZones(data);
  $: hasData = data && data.length > 0;
</script>

{#if hasData}
  <svg 
    {width} 
    {height} 
    class={className}
    viewBox={`0 0 ${width} ${height}`}
    preserveAspectRatio="none"
    aria-label="Sparkline chart showing data trend"
  >
    <!-- Highlight zones for values above threshold -->
    {#each highlightZones as zone}
      <rect
        x={zone.x}
        y={0}
        width={zone.width}
        height={height}
        fill="currentColor"
        opacity="0.1"
        class="text-amber-500 dark:text-amber-400"
      />
    {/each}
    
    <!-- Zero line if data includes negative values -->
    {#if Math.min(...data) < 0}
      {@const zeroY = height - ((0 - Math.min(...data)) / (Math.max(...data) - Math.min(...data))) * height}
      <line
        x1={0}
        y1={zeroY}
        x2={width}
        y2={zeroY}
        stroke="currentColor"
        stroke-width="0.5"
        opacity="0.3"
        stroke-dasharray="2 2"
      />
    {/if}
    
    <!-- Main sparkline path -->
    <path
      d={path}
      fill={fillColor}
      stroke={strokeColor}
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
      vector-effect="non-scaling-stroke"
    />
    
    <!-- Points for emphasis (optional, only show for small datasets) -->
    {#if data.length <= 10}
      {#each data as value, index}
        {@const max = Math.max(...data, 1)}
        {@const min = Math.min(...data, 0)}
        {@const range = max - min || 1}
        {@const x = (index / (data.length - 1)) * width}
        {@const y = height - ((value - min) / range) * height}
        <circle
          cx={x}
          cy={y}
          r="1.5"
          fill={strokeColor}
          opacity={value > highlightThreshold ? "1" : "0.6"}
        />
      {/each}
    {/if}
  </svg>
{:else}
  <!-- Empty state -->
  <svg 
    {width} 
    {height} 
    class={className}
    viewBox={`0 0 ${width} ${height}`}
    aria-label="No data available"
  >
    <line
      x1={0}
      y1={height / 2}
      x2={width}
      y2={height / 2}
      stroke="currentColor"
      stroke-width="1"
      opacity="0.2"
      stroke-dasharray="2 2"
    />
  </svg>
{/if}