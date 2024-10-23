<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'dashboard/composables/useI18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

import AddFunction from './AddFunction.vue';
import EditLabel from './EditFunction.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedLabel = ref({});

const records = computed(() => getters['chatbotFunction/getFunctions'].value);

const uiFlags = computed(() => getters['labels/getUIFlags'].value);

const deleteMessage = computed(() => ` ${selectedLabel.value.name}?`);

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  selectedLabel.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedLabel.value = response;
};
const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteLabel = async id => {
  try {
    await store.dispatch('chatbotFunction/delete', id);
    useAlert(t('LABEL_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('LABEL_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    loading.value[selectedLabel.value.id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedLabel.value.id] = true;
  closeDeletePopup();
  deleteLabel(selectedLabel.value.id);
};

onBeforeMount(async () => {
  await store.dispatch('chatbotFunction/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('LABEL_MGMT.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('CHATBOT_SETTINGS.FUNCTIONS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('CHATBOT_SETTINGS.FUNCTIONS.HEADER')"
        :description="$t('CHATBOT_SETTINGS.FUNCTIONS.DESCRIPTION')"
        :link-text="$t('LABEL_MGMT.LEARN_MORE')"
        feature-name="labels"
      >
        <template #actions>
          <woot-button
            class="button nice rounded-md"
            icon="add-circle"
            @click="openAddPopup"
          >
            {{ $t('CHATBOT_SETTINGS.FUNCTIONS.HEADER_BTN_TXT') }}
          </woot-button>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <table
        class="min-w-full overflow-x-auto divide-y divide-slate-75 dark:divide-slate-700"
      >
        <thead>
          <th
            v-for="thHeader in $t(
              'CHATBOT_SETTINGS.FUNCTIONS.LIST.TABLE_HEADER'
            )"
            :key="thHeader"
            class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-slate-700 dark:text-slate-300"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody
          class="divide-y divide-slate-25 dark:divide-slate-800 flex-1 text-slate-700 dark:text-slate-100"
        >
          <tr v-for="(item, index) in records" :key="item.name">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span
                class="font-medium break-words text-slate-700 dark:text-slate-100 mb-1"
              >
                {{ item.name }}
              </span>
            </td>
            <td class="py-4 min-w-xs">
              <div class="flex gap-1">
                <woot-button
                  v-tooltip.top="$t('LABEL_MGMT.FORM.EDIT')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  :is-loading="loading[item.id]"
                  icon="edit"
                  @click="openEditPopup(item)"
                />
                <woot-button
                  v-tooltip.top="$t('LABEL_MGMT.FORM.DELETE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  :is-loading="loading[item.id]"
                  @click="openDeletePopup(item, index)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <AddFunction @close="hideAddPopup" />
    </woot-modal>

    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <EditLabel :selected-response="selectedLabel" @close="hideEditPopup" />
    </woot-modal>

    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('LABEL_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('LABEL_MGMT.DELETE.CONFIRM.YES')"
      :reject-text="$t('LABEL_MGMT.DELETE.CONFIRM.NO')"
    />
  </SettingsLayout>
</template>
