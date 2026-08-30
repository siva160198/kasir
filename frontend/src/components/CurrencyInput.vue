<script setup>
import { computed, inject, useAttrs } from "vue";
import { formFieldContextKey } from "./formFieldContext";
defineOptions({ inheritAttrs: false });
const attrs = useAttrs();
const field = inject(formFieldContextKey, null);
const model = defineModel({ type: [Number, String], default: 0 });
const shown = computed(() => new Intl.NumberFormat("id-ID").format(Number(model.value) || 0));
function input(event) { model.value = Number(event.target.value.replace(/\D/g, "")) || 0; }
</script>
<template><span class="relative flex"><span class="absolute inset-y-0 left-0 flex items-center pl-4 text-sm text-gray-500">Rp</span><input v-bind="attrs" inputmode="numeric" :value="shown" :id="attrs.id || field?.controlId.value" :aria-describedby="attrs['aria-describedby'] || field?.describedBy.value" :aria-invalid="attrs['aria-invalid'] ?? field?.invalid.value" class="w-full rounded-lg border border-gray-300 bg-white py-2.5 pl-11 pr-4 text-sm text-gray-900 shadow-sm aria-[invalid=true]:border-error-500 dark:border-gray-700 dark:bg-gray-900 dark:text-white" @input="input" /></span></template>
