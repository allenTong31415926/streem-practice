<template>
  <div id="app">
    <SearchForm />
  </div>
</template>

<script lang="ts">
import { defineComponent } from "vue";
import SearchForm from "@/components/SearchForm.vue";

export default defineComponent({
  name: "App",
  components: {
    SearchForm,
  },
});
</script>

<style>
#app {
  font-family: Arial, sans-serif;
  text-align: center;
  margin-top: 50px;
}
</style>
