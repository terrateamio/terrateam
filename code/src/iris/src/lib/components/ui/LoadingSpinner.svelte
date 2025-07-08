<script lang="ts">
  export let size: 'sm' | 'md' | 'lg' = 'md';
  export let color: string = '#009bff';
  export let centered: boolean = true;

  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-6 w-6', 
    lg: 'h-8 w-8'
  };

  const containerClasses = centered ? 'flex justify-center py-12' : '';
</script>

<div class={containerClasses}>
  <div 
    class="animate-spin rounded-full border-b-2 {sizeClasses[size]}" 
    style="border-color: {color};"
  ></div>
</div>