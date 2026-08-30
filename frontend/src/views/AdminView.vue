<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from "vue";
import ApexCharts from "apexcharts";
import {
  ArrowDown,
  ArrowUp,
  Box,
  ChevronRight,
  EllipsisVertical,
  PackageOpen,
  ReceiptText,
  ShoppingCart,
  TrendingUp,
  UsersRound,
  WalletCards,
} from "@lucide/vue";
import AdminLayout from "../components/admin/AdminLayout.vue";
import { apiFetch } from "../services/api";
import { toast } from "../services/toast";
import { locale, t } from "../services/i18n";

const dashboard = ref(null);
const loadFailed = ref(false);
const loading = ref(false);
const selectedPeriod = ref("today");
const showLowStock = ref(false);
const salesChartElement = ref(null);
let salesChart;
const localeCode = computed(() => locale.value === "en" ? "en-US" : "id-ID");
const rupiah = (value) => new Intl.NumberFormat(localeCode.value, { style: "currency", currency: "IDR", maximumFractionDigits: 0 }).format(Number(value || 0));
const shortMoney = (value) => new Intl.NumberFormat(localeCode.value, { notation: "compact", maximumFractionDigits: 1 }).format(Number(value || 0));
const number = (value) => new Intl.NumberFormat(localeCode.value).format(Number(value || 0));
const time = (value) => new Intl.DateTimeFormat(localeCode.value, { hour: "2-digit", minute: "2-digit" }).format(new Date(value));
const date = (value) => new Intl.DateTimeFormat(localeCode.value, { day: "2-digit", month: "short" }).format(new Date(value));
const paymentName = (method) => t(`payment.${method}`);

const paymentTotal = computed(() => (dashboard.value?.payments || []).reduce((sum, item) => sum + Math.max(item.total, 0), 0));
const paymentColors = ["#465fff", "#12b76a", "#f79009", "#7a5af8"];
const donutStyle = computed(() => {
  let cursor = 0;
  const segments = (dashboard.value?.payments || []).map((item, index) => {
    const start = cursor;
    cursor += paymentTotal.value ? (Math.max(item.total, 0) / paymentTotal.value) * 100 : 0;
    return `${paymentColors[index]} ${start}% ${cursor}%`;
  });
  return { background: paymentTotal.value ? `conic-gradient(${segments.join(",")})` : "#f2f4f7" };
});
const topProductMax = computed(() => Math.max(...(dashboard.value?.top_products || []).map((item) => item.quantity), 1));
const periodOptions = computed(() => [
  { value: "today", label: t("dashboard.period_today"), description: t("dashboard.previous_day") },
  { value: "week", label: t("dashboard.period_week"), description: t("dashboard.previous_week") },
  { value: "month", label: t("dashboard.period_month"), description: t("dashboard.previous_period") },
]);
const periodLabel = computed(() => periodOptions.value.find((item) => item.value === selectedPeriod.value)?.label || t("dashboard.period_today"));
const comparisonLabel = computed(() => periodOptions.value.find((item) => item.value === selectedPeriod.value)?.description || t("dashboard.previous_period"));
const metrics = computed(() => dashboard.value ? [
  { key: "revenue", label: t("dashboard.revenue", { period: periodLabel.value.toLowerCase() }), value: rupiah(dashboard.value.summary.net_sales), icon: WalletCards, note: t("dashboard.compared_to", { period: comparisonLabel.value }), change: dashboard.value.summary.sales_change },
  { key: "transactions", label: t("dashboard.total_transactions"), value: number(dashboard.value.summary.transactions), icon: ShoppingCart, note: t("dashboard.average", { amount: rupiah(dashboard.value.summary.average_transaction) }) },
  { key: "profit", label: t("dashboard.gross_profit"), value: rupiah(dashboard.value.summary.gross_profit), icon: TrendingUp, note: t("dashboard.after_cost") },
  { key: "stock", label: t("dashboard.low_stock"), value: number(dashboard.value.stock.low_count), icon: Box, note: t("dashboard.out_products", { count: dashboard.value.stock.out_count }), warning: dashboard.value.stock.out_count > 0 },
] : []);

function chartLabel(item) {
  if (selectedPeriod.value !== "week") return item.label;
  return new Intl.DateTimeFormat(localeCode.value, { weekday: "short" }).format(new Date(`${item.date}T12:00:00`));
}

async function renderSalesChart() {
  salesChart?.destroy();
  salesChart = null;
  await nextTick();
  if (!salesChartElement.value || !dashboard.value) return;
  salesChart = new ApexCharts(salesChartElement.value, {
    series: [{ name: t("dashboard.revenue", { period: periodLabel.value.toLowerCase() }), data: dashboard.value.weekly_sales.map((item) => item.net_sales) }],
    colors: ["#465fff"],
    chart: { fontFamily: "Outfit, sans-serif", type: "bar", height: 180, toolbar: { show: false }, animations: { enabled: true } },
    plotOptions: { bar: { horizontal: false, columnWidth: "39%", borderRadius: 5, borderRadiusApplication: "end" } },
    dataLabels: { enabled: false }, stroke: { show: true, width: 4, colors: ["transparent"] },
    xaxis: { categories: dashboard.value.weekly_sales.map(chartLabel), axisBorder: { show: false }, axisTicks: { show: false }, labels: { rotate: 0, hideOverlappingLabels: true, style: { colors: "#667085", fontSize: "12px" } } },
    yaxis: { labels: { formatter: (value) => shortMoney(value), style: { colors: "#98a2b3", fontSize: "11px" } } },
    grid: { borderColor: "#e4e7ec", strokeDashArray: 4, xaxis: { lines: { show: false } }, padding: { left: 2, right: 4 } },
    fill: { opacity: 1 }, legend: { show: false },
    tooltip: { x: { show: true }, y: { formatter: (value) => rupiah(value), title: { formatter: () => `${t("dashboard.revenue", { period: periodLabel.value.toLowerCase() })}: ` } } },
  });
  await salesChart.render();
}

async function loadDashboard(period = selectedPeriod.value) {
  loading.value = true;
  try {
    selectedPeriod.value = period;
    dashboard.value = await apiFetch(`/api/v1/admin/dashboard?period=${period}`);
    loadFailed.value = false;
    await renderSalesChart();
  }
  catch (error) { loadFailed.value = true; toast.error(error.message); }
  finally { loading.value = false; }
}

onMounted(() => loadDashboard());
onUnmounted(() => salesChart?.destroy());
watch(locale, () => renderSalesChart());
</script>

<template>
  <AdminLayout>
    <main class="mx-auto max-w-[1536px] space-y-6">
      <header class="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
        <div><h1 class="text-2xl font-semibold text-gray-800 dark:text-white/90">{{ t('dashboard.title') }}</h1><p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ t('dashboard.business_summary') }}</p></div>
        <div class="inline-flex rounded-lg border border-gray-200 bg-white p-1 shadow-sm dark:border-gray-700 dark:bg-gray-800">
          <button v-for="option in periodOptions" :key="option.value" type="button" class="rounded-md px-3 py-1.5 text-sm font-medium transition" :class="selectedPeriod === option.value ? 'bg-brand-500 text-white shadow-sm' : 'text-gray-500 hover:text-gray-800 dark:text-gray-400 dark:hover:text-white'" :disabled="loading" @click="loadDashboard(option.value)">{{ option.label }}</button>
        </div>
      </header>

      <div v-if="loadFailed" class="rounded-2xl border border-error-200 bg-error-50 px-5 py-12 text-center text-sm text-error-600">{{ t('dashboard.load_failed') }}</div>
      <div v-else-if="!dashboard" class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4"><div v-for="item in 4" :key="item" class="h-40 animate-pulse rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]"></div></div>

      <div v-else :class="loading ? 'opacity-60' : 'opacity-100'" class="space-y-6 transition-opacity">
        <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <article v-for="metric in metrics" :key="metric.label" class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] md:p-6">
            <span class="flex h-12 w-12 items-center justify-center rounded-xl bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-white/90"><component :is="metric.icon" :size="23" /></span>
            <div class="mt-5 flex items-end justify-between gap-3">
              <div class="min-w-0"><p class="text-sm text-gray-500 dark:text-gray-400">{{ metric.label }}</p><h3 class="mt-1 truncate text-2xl font-bold text-gray-800 dark:text-white/90">{{ metric.value }}</h3></div>
              <span v-if="metric.change !== undefined" class="mb-1 inline-flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium" :class="metric.change >= 0 ? 'bg-success-50 text-success-600 dark:bg-success-500/15' : 'bg-error-50 text-error-600 dark:bg-error-500/15'"><ArrowUp v-if="metric.change >= 0" :size="13"/><ArrowDown v-else :size="13"/>{{ Math.abs(metric.change) }}%</span>
            </div>
            <p class="mt-2 text-xs" :class="metric.warning ? 'text-error-500' : 'text-gray-400'">{{ metric.note }}</p>
            <button v-if="metric.key === 'stock'" type="button" class="mt-4 inline-flex items-center gap-1 text-xs font-semibold text-brand-500 hover:text-brand-600" @click="showLowStock = !showLowStock">{{ t(showLowStock ? 'dashboard.close_list' : 'dashboard.view_low_stock') }} <ChevronRight :size="14" :class="showLowStock ? 'rotate-90' : ''" class="transition-transform"/></button>
          </article>
        </section>

        <section v-if="showLowStock" class="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
          <div class="flex items-center justify-between border-b border-gray-200 px-5 py-4 dark:border-gray-800 sm:px-6"><div><h2 class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ t('dashboard.low_stock') }}</h2><p class="mt-1 text-sm text-gray-500">{{ t('dashboard.low_stock_hint') }}</p></div><RouterLink to="/admin/inventory" class="rounded-lg border border-gray-200 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300">{{ t('dashboard.open_inventory') }}</RouterLink></div>
          <div class="overflow-x-auto"><table class="w-full min-w-[620px] text-left"><thead class="bg-gray-50/60 text-xs font-medium uppercase text-gray-500 dark:bg-white/[0.02]"><tr><th class="px-6 py-3">{{ t('products.name') }}</th><th class="px-6 py-3">{{ t('products.sku') }}</th><th class="px-6 py-3 text-right">{{ t('dashboard.current_stock') }}</th><th class="px-6 py-3 text-right">{{ t('dashboard.minimum_stock') }}</th><th class="px-6 py-3">{{ t('common.status') }}</th></tr></thead><tbody class="divide-y divide-gray-100 dark:divide-gray-800"><tr v-for="product in dashboard.stock.items" :key="product.id"><td class="px-6 py-3.5 text-sm font-medium text-gray-800 dark:text-white/90">{{ product.name }}</td><td class="px-6 py-3.5 text-sm text-gray-500">{{ product.sku }}</td><td class="px-6 py-3.5 text-right text-sm font-semibold text-gray-800 dark:text-white/90">{{ product.current_stock }} {{ product.unit }}</td><td class="px-6 py-3.5 text-right text-sm text-gray-500">{{ product.minimum_stock }} {{ product.unit }}</td><td class="px-6 py-3.5"><span class="rounded-full px-2.5 py-1 text-xs font-medium" :class="product.current_stock === 0 ? 'bg-error-50 text-error-600 dark:bg-error-500/10' : 'bg-warning-50 text-warning-600 dark:bg-warning-500/10'">{{ t(product.current_stock === 0 ? 'dashboard.out' : 'dashboard.low') }}</span></td></tr></tbody></table></div>
        </section>

        <section>
          <article class="overflow-hidden rounded-2xl border border-gray-200 bg-white px-5 pt-5 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6 sm:pt-6">
            <div class="flex items-center justify-between"><div><h2 class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ t('dashboard.sales_statistics') }}</h2><p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ t('dashboard.net_revenue_period', { period: periodLabel }) }}</p></div><button type="button" :aria-label="t('dashboard.chart_menu')" class="rounded-lg p-1.5 text-gray-400 transition hover:bg-gray-100 hover:text-gray-700 dark:hover:bg-white/5 dark:hover:text-white"><EllipsisVertical :size="23"/></button></div>
            <div class="custom-scrollbar max-w-full overflow-x-auto">
              <div ref="salesChartElement" :class="selectedPeriod === 'month' ? 'min-w-[1000px]' : 'min-w-[690px] xl:min-w-full'" class="-ml-3 h-[210px] pt-2 sm:-ml-5"></div>
            </div>
          </article>
        </section>

        <section>
          <article class="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
            <div class="flex items-center justify-between border-b border-gray-200 px-5 py-4 dark:border-gray-800 sm:px-6"><div><h2 class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ t('dashboard.latest_transactions') }}</h2><p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ t('dashboard.completed_transactions') }}</p></div><RouterLink to="/admin/sales" class="rounded-lg border border-gray-200 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/5">{{ t('dashboard.view_all') }}</RouterLink></div>
            <div class="overflow-x-auto"><table class="w-full min-w-[680px] text-left"><thead class="border-b border-gray-100 bg-gray-50/60 text-xs font-medium uppercase text-gray-500 dark:border-gray-800 dark:bg-white/[0.02]"><tr><th class="px-6 py-3">{{ t('dashboard.transaction') }}</th><th class="px-6 py-3">{{ t('dashboard.cashier') }}</th><th class="px-6 py-3">{{ t('dashboard.payment') }}</th><th class="px-6 py-3">{{ t('dashboard.time') }}</th><th class="px-6 py-3 text-right">{{ t('pos.total') }}</th></tr></thead><tbody class="divide-y divide-gray-100 dark:divide-gray-800"><tr v-for="sale in dashboard.recent_sales" :key="sale.id" class="hover:bg-gray-50/50 dark:hover:bg-white/[0.02]"><td class="px-6 py-4 text-sm font-medium text-gray-800 dark:text-white/90">{{ sale.number }}</td><td class="px-6 py-4 text-sm text-gray-500">{{ sale.cashier }}</td><td class="px-6 py-4"><span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-600 dark:bg-gray-800 dark:text-gray-300">{{ paymentName(sale.payment_method) }}</span></td><td class="px-6 py-4 text-sm text-gray-500">{{ date(sale.completed_at) }}, {{ time(sale.completed_at) }}</td><td class="px-6 py-4 text-right text-sm font-semibold text-gray-800 dark:text-white/90">{{ rupiah(sale.total) }}</td></tr></tbody></table></div>
          </article>
        </section>

        <section class="grid items-start gap-6 lg:grid-cols-2 xl:grid-cols-3">
          <article class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] sm:p-6">
            <div><h2 class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ t('dashboard.payment_methods') }}</h2><p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ t('dashboard.payment_composition', { period: periodLabel }) }}</p></div>
            <div class="relative mx-auto mt-7 h-40 w-40 rounded-full p-5" :style="donutStyle"><div class="flex h-full w-full flex-col items-center justify-center rounded-full bg-white dark:bg-gray-900"><span class="text-xs text-gray-500">{{ t('pos.total') }}</span><strong class="mt-1 text-lg text-gray-800 dark:text-white/90">{{ shortMoney(paymentTotal) }}</strong></div></div>
            <div class="mt-7 grid grid-cols-2 gap-x-4 gap-y-4"><div v-for="(payment, index) in dashboard.payments" :key="payment.method"><div class="flex items-center gap-2"><span class="h-2.5 w-2.5 rounded-full" :style="{ backgroundColor: paymentColors[index] }"></span><span class="text-xs text-gray-500 dark:text-gray-400">{{ paymentName(payment.method) }}</span></div><p class="mt-1 pl-[18px] text-sm font-semibold text-gray-800 dark:text-white/90">{{ rupiah(payment.total) }}</p></div></div>
          </article>

          <article class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] sm:p-6"><div class="flex items-center justify-between"><div><h2 class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ t('dashboard.top_products') }}</h2><p class="mt-1 text-sm text-gray-500">{{ periodLabel }}</p></div><PackageOpen :size="22" class="text-gray-400"/></div><div class="mt-6 space-y-5"><div v-for="(product, index) in dashboard.top_products.slice(0, 4)" :key="product.name"><div class="mb-2 flex items-center justify-between gap-3"><div class="flex min-w-0 items-center gap-3"><span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gray-100 text-xs font-semibold text-gray-600 dark:bg-gray-800 dark:text-gray-300">{{ index + 1 }}</span><div class="min-w-0"><p class="truncate text-sm font-medium text-gray-800 dark:text-white/90">{{ product.name }}</p><p class="text-xs text-gray-400">{{ rupiah(product.revenue) }}</p></div></div><span class="shrink-0 text-xs font-semibold text-gray-600 dark:text-gray-300">{{ t('dashboard.sold', { count: product.quantity }) }}</span></div><div class="ml-11 h-1.5 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-800"><div class="h-full rounded-full bg-brand-500" :style="{ width: `${product.quantity / topProductMax * 100}%` }"></div></div></div></div></article>

          <article class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] sm:p-6 lg:col-span-2 xl:col-span-1"><div class="flex items-center justify-between"><div><h2 class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ t('dashboard.store_operations') }}</h2><p class="mt-1 text-sm text-gray-500">{{ t('dashboard.operations_hint') }}</p></div><UsersRound :size="22" class="text-gray-400"/></div><div class="mt-6 rounded-xl bg-gray-50 p-4 dark:bg-white/[0.03]"><div class="flex items-center justify-between"><div class="flex items-center gap-3"><span class="flex h-10 w-10 items-center justify-center rounded-xl bg-success-50 text-success-600 dark:bg-success-500/10"><UsersRound :size="20"/></span><div><p class="text-sm font-semibold text-gray-800 dark:text-white/90">{{ t('dashboard.active_shifts', { count: dashboard.shifts.open_count }) }}</p><p class="text-xs text-gray-500">{{ t('dashboard.cashiers_working') }}</p></div></div><RouterLink to="/admin/shift-history" class="text-sm font-medium text-brand-500">{{ t('dashboard.history') }}</RouterLink></div></div><div class="mt-4 flex items-center justify-between rounded-xl border border-gray-100 p-4 dark:border-gray-800"><div><p class="text-sm font-medium text-gray-800 dark:text-white/90">{{ t('dashboard.stock_attention') }}</p><p class="mt-1 text-xs text-gray-500">{{ t('dashboard.out_of_low', { out: dashboard.stock.out_count, low: dashboard.stock.low_count }) }}</p></div><button type="button" class="rounded-lg bg-warning-50 px-2.5 py-1.5 text-xs font-semibold text-warning-600 dark:bg-warning-500/10" @click="showLowStock = true">{{ t('dashboard.view_stock') }}</button></div></article>
        </section>
      </div>
    </main>
  </AdminLayout>
</template>
