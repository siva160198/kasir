import { createRouter, createWebHistory } from "vue-router";
import { useAuth } from "./services/auth";
import { toast } from "./services/toast";
import {
  finishNavigationLoading,
  startNavigationLoading,
} from "./services/navigationLoading";
import { t } from "./services/i18n";

const LoginView = () => import("./views/LoginView.vue");
const ForgotPasswordView = () => import("./views/ForgotPasswordView.vue");
const ResetPasswordView = () => import("./views/ResetPasswordView.vue");
const EmailRevertView = () => import("./views/EmailRevertView.vue");
const RegisterView = () => import("./views/RegisterView.vue");
const AdminView = () => import("./views/AdminView.vue");
const AdminUsersView = () => import("./views/AdminUsersView.vue");
const AdminAuditLogsView = () => import("./views/AdminAuditLogsView.vue");
const AdminRolesView = () => import("./views/AdminRolesView.vue");
const AdminCategoriesView = () => import("./views/AdminCategoriesView.vue");
const AdminProductsView = () => import("./views/AdminProductsView.vue");
const AdminInventoryView = () => import("./views/AdminInventoryView.vue");
const AdminStockAdjustmentsView = () =>
  import("./views/AdminStockAdjustmentsView.vue");
const AdminStockMovementsView = () =>
  import("./views/AdminStockMovementsView.vue");
const AdminMyShiftView = () => import("./views/AdminMyShiftView.vue");
const AdminShiftHistoryView = () => import("./views/AdminShiftHistoryView.vue");
const AdminPosView = () => import("./views/AdminPosView.vue");
const AdminSalesView = () => import("./views/AdminSalesView.vue");
const AdminReportsView = () => import("./views/AdminReportsView.vue");
const AdminSuppliersView = () => import("./views/AdminSuppliersView.vue");
const AdminPurchasesView = () => import("./views/AdminPurchasesView.vue");
const AdminStoreSettingsView = () =>
  import("./views/AdminStoreSettingsView.vue");
const AdminExpensesView = () => import("./views/AdminExpensesView.vue");
const AdminStockCountsView = () => import("./views/AdminStockCountsView.vue");
const AdminCustomersView = () => import("./views/AdminCustomersView.vue");
const AdminPromotionsView = () => import("./views/AdminPromotionsView.vue");
const ProfileView = () => import("./views/ProfileView.vue");
const AdminJobsView = () => import("./views/AdminJobsView.vue");
const AdminApiDocsView = () => import("./views/AdminApiDocsView.vue");
const AdminApprovalsView = () => import("./views/AdminApprovalsView.vue");
const ForbiddenView = () => import("./views/ForbiddenView.vue");
const NotFoundView = () => import("./views/NotFoundView.vue");
const AppErrorView = () => import("./views/AppErrorView.vue");
const { loadUser, can } = useAuth();

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: "/", redirect: "/login" },
    { path: "/login", component: LoginView },
    { path: "/forgot-password", component: ForgotPasswordView },
    { path: "/reset-password", component: ResetPasswordView },
    { path: "/email-revert", component: EmailRevertView },
    { path: "/register", component: RegisterView },
    { path: "/403", component: ForbiddenView },
    { path: "/error", component: AppErrorView },
    {
      path: "/admin",
      component: AdminView,
      meta: { permission: "dashboard.view", layout: "admin" },
    },
    {
      path: "/admin/users",
      component: AdminUsersView,
      meta: { permission: "users.view", layout: "admin" },
    },
    {
      path: "/admin/roles",
      component: AdminRolesView,
      meta: { permission: "roles.view", layout: "admin" },
    },
    {
      path: "/admin/categories",
      component: AdminCategoriesView,
      meta: { permission: "categories.view", layout: "admin" },
    },
    {
      path: "/admin/products",
      component: AdminProductsView,
      meta: { permission: "products.view", layout: "admin" },
    },
    {
      path: "/admin/inventory",
      component: AdminInventoryView,
      meta: { permission: "inventory.view", layout: "admin" },
    },
    {
      path: "/admin/stock-adjustments",
      component: AdminStockAdjustmentsView,
      meta: { permission: "stock_adjustments.create", layout: "admin" },
    },
    {
      path: "/admin/stock-movements",
      component: AdminStockMovementsView,
      meta: { permission: "stock_movements.view", layout: "admin" },
    },
    {
      path: "/admin/my-shift",
      component: AdminMyShiftView,
      meta: { permission: "cashier_shifts.view_own", layout: "admin" },
    },
    {
      path: "/admin/shift-history",
      component: AdminShiftHistoryView,
      meta: { permission: "cashier_shifts.view_own", layout: "admin" },
    },
    {
      path: "/admin/pos",
      component: AdminPosView,
      meta: { permission: "sales.create", layout: "admin" },
    },
    {
      path: "/admin/sales",
      component: AdminSalesView,
      meta: { permission: "sales.view_own", layout: "admin" },
    },
    {
      path: "/admin/reports",
      component: AdminReportsView,
      meta: { permission: "reports.view", layout: "admin" },
    },
    {
      path: "/admin/suppliers",
      component: AdminSuppliersView,
      meta: { permission: "suppliers.view", layout: "admin" },
    },
    {
      path: "/admin/purchases",
      component: AdminPurchasesView,
      meta: { permission: "purchases.view", layout: "admin" },
    },
    {
      path: "/admin/store-settings",
      component: AdminStoreSettingsView,
      meta: { permission: "store_settings.manage", layout: "admin" },
    },
    {
      path: "/admin/expenses",
      component: AdminExpensesView,
      meta: { permission: "expenses.view", layout: "admin" },
    },
    {
      path: "/admin/stock-counts",
      component: AdminStockCountsView,
      meta: { permission: "stock_counts.view", layout: "admin" },
    },
    {
      path: "/admin/customers",
      component: AdminCustomersView,
      meta: { permission: "customers.view", layout: "admin" },
    },
    {
      path: "/admin/promotions",
      component: AdminPromotionsView,
      meta: { permission: "promotions.view", layout: "admin" },
    },
    {
      path: "/admin/audit-logs",
      component: AdminAuditLogsView,
      meta: { permission: "audit_logs.view", layout: "admin" },
    },
    { path: "/admin/sessions", redirect: "/profile" },
    { path: "/account/security", redirect: "/profile" },
    {
      path: "/profile",
      component: ProfileView,
      meta: { permission: "profile.view", layout: "admin" },
    },
    {
      path: "/admin/jobs",
      component: AdminJobsView,
      meta: { permission: "jobs.view", layout: "admin" },
    },
    {
      path: "/admin/api-docs",
      component: AdminApiDocsView,
      meta: { permission: "api_docs.view", layout: "admin" },
    },
    {
      path: "/admin/security-approvals",
      component: AdminApprovalsView,
      meta: { permission: "security_approvals.view", layout: "admin" },
    },
    { path: "/:pathMatch(.*)*", component: NotFoundView },
  ],
});

router.beforeEach(async (to) => {
  startNavigationLoading();
  if (!to.meta.permission) return true;
  const user = await loadUser();
  if (!user) {
    toast.warning(t("auth.login_required"));
    return { path: "/login", query: { redirect: to.fullPath } };
  }
  if (!can(to.meta.permission)) return { path: "/403" };
  return true;
});

router.afterEach(() => finishNavigationLoading());

router.onError((error) => {
  finishNavigationLoading();
  console.error("Vue Router error:", error);
  if (router.currentRoute.value.path !== "/error") router.replace("/error");
});

export default router;
