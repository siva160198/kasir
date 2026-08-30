import { ref } from "vue";
import { apiFetch } from "./api";
const profile = ref({ store_name: "KASIR", receipt_footer: "Terima kasih", receipt_width: 58 });
let pending;
export function useStoreProfile() {
  async function loadStoreProfile() {
    if (!pending) pending = apiFetch("/api/v1/store_profile").then((response) => { profile.value = response.store_profile; return profile.value; }).finally(() => { pending = null; });
    return pending;
  }
  return { storeProfile: profile, loadStoreProfile };
}
