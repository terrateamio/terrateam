<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  
  interface $$Props {
    currentPage: number;
    hasNext: boolean;
    hasPrevious?: boolean;
    isLoading?: boolean;
  }
  
  export let currentPage: number;
  export let hasNext: boolean;
  export let hasPrevious: boolean = currentPage > 1;
  export let isLoading: boolean = false;
  
  const dispatch = createEventDispatcher<{ 
    previous: void;
    next: void;
  }>();
  
  function handlePrevious() {
    if (hasPrevious && !isLoading) {
      dispatch('previous');
    }
  }
  
  function handleNext() {
    if (hasNext && !isLoading) {
      dispatch('next');
    }
  }
</script>

<div class="flex items-center justify-between border-t border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 px-4 py-3 sm:px-6">
  <div class="flex flex-1 justify-between sm:hidden">
    <!-- Mobile pagination -->
    <button
      on:click={handlePrevious}
      disabled={!hasPrevious || isLoading}
      class="relative inline-flex items-center rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed"
    >
      Previous
    </button>
    <button
      on:click={handleNext}
      disabled={!hasNext || isLoading}
      class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed"
    >
      Next
    </button>
  </div>

  <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
    <div>
      <p class="text-sm text-gray-700 dark:text-gray-300">
        Page <span class="font-medium">{currentPage}</span>
        {#if hasNext}
          of many
        {:else}
          (last page)
        {/if}
      </p>
    </div>

    <div>
      <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
        <!-- Previous button -->
        <button
          on:click={handlePrevious}
          disabled={!hasPrevious || isLoading}
          class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 dark:ring-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 focus:z-20 focus:outline-offset-0 disabled:opacity-50 disabled:cursor-not-allowed bg-white dark:bg-gray-800"
        >
          <span class="sr-only">Previous</span>
          {#if isLoading}
            <svg class="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          {:else}
            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clip-rule="evenodd" />
            </svg>
          {/if}
        </button>

        <!-- Current page indicator -->
        <span class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-900 dark:text-gray-100 ring-1 ring-inset ring-gray-300 dark:ring-gray-600 bg-white dark:bg-gray-800">
          {currentPage}
        </span>

        <!-- Next button -->
        <button
          on:click={handleNext}
          disabled={!hasNext || isLoading}
          class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 dark:ring-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 focus:z-20 focus:outline-offset-0 disabled:opacity-50 disabled:cursor-not-allowed bg-white dark:bg-gray-800"
        >
          <span class="sr-only">Next</span>
          {#if isLoading}
            <svg class="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          {:else}
            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clip-rule="evenodd" />
            </svg>
          {/if}
        </button>
      </nav>
    </div>
  </div>
</div>