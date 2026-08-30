<script setup>
import { defineAsyncComponent } from 'vue'
import { useRoute } from 'vue-router'
import { appError } from './services/errorState'
import ToastContainer from './components/ToastContainer.vue'
import NavigationLoader from './components/NavigationLoader.vue'
import LanguageSwitcher from './components/LanguageSwitcher.vue'

const route = useRoute()
const AppErrorView = defineAsyncComponent(() => import('./views/AppErrorView.vue'))
</script>

<template>
  <div class="min-h-screen bg-slate-50 text-slate-900">
    <header v-if="route.meta.layout !== 'admin'" class="border-b border-slate-200 bg-white">
      <nav class="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <RouterLink to="/" class="text-xl font-bold tracking-tight">Kasir</RouterLink>
        <div class="flex items-center">
          <LanguageSwitcher />
        </div>
      </nav>
    </header>
    <AppErrorView v-if="appError" />
    <RouterView v-else />
    <ToastContainer />
    <NavigationLoader />
  </div>
</template>
