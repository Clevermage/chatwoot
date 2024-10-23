<script>
import { useVuelidate } from '@vuelidate/core';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConfig } from 'dashboard/composables/useConfig';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

import semver from 'semver';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

import FileUpload from 'vue-upload-component';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview';
import { ALLOWED_FILE_TYPES } from 'shared/constants/chatbot';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    FileUpload,
    AttachmentPreview,
    SettingsLayout,
    BaseSettingsHeader,
    Spinner,
  },
  mixins: [fileUploadMixin],
  setup() {
    const { updateUISettings } = useUISettings();
    const { enabledLanguages } = useConfig();
    const v$ = useVuelidate();

    return { updateUISettings, v$, enabledLanguages };
  },
  data() {
    return {
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
      loading: {},
      loadingButton: false,
      locale: 'es',
      id: '',
      attachedFiles: [],
      files: [],
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      uiFlags: 'accounts/getUIFlags',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    deleteMessage() {
      return ` ${this.selectedResponse.name}?`;
    },
    showAutoResolutionConfig() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.AUTO_RESOLVE_CONVERSATIONS
      );
    },
    hasAnUpdateAvailable() {
      if (!semver.valid(this.latestChatwootVersion)) {
        return false;
      }

      return semver.lt(
        this.globalConfig.appVersion,
        this.latestChatwootVersion
      );
    },
    languagesSortedByCode() {
      const enabledLanguages = [...this.enabledLanguages];
      return enabledLanguages.sort((l1, l2) =>
        l1.iso_639_1_code.localeCompare(l2.iso_639_1_code)
      );
    },
    isUpdating() {
      return this.uiFlags.isUpdating;
    },

    featureInboundEmailEnabled() {
      return !!this.features?.inbound_emails;
    },

    featureCustomReplyDomainEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_domain
      );
    },

    featureCustomReplyEmailEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_email
      );
    },

    getAccountId() {
      return this.id.toString();
    },
    hasAttachments() {
      return this.attachedFiles.length;
    },
    allowedFileTypes() {
      return ALLOWED_FILE_TYPES;
    },
  },
  mounted() {
    this.initializeAccount();
  },
  methods: {
    async initializeAccount() {
      try {
        const { id, files } = await this.$store.dispatch('chatbot/get');
        this.id = id;
        this.files = files;
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
      }
    },

    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedResponse = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedResponse.id] = true;
      this.closeDeletePopup();
      this.deleteFile(this.selectedResponse.id);
    },

    async updateDocument() {
      try {
        this.loadingButton = true;
        const payload = {
          id: this.id,
        };
        if (this.attachedFiles && this.attachedFiles.length) {
          payload.files = [];
          this.setAttachmentPayload(payload);
        }
        await this.$store.dispatch('chatbot/updateDocuments', payload);
        this.loadingButton = false;
        useAlert(this.$t('KNOWLEDGE_CHATBOT.ADD.API.SUCCESS_MESSAGE'));
        this.initializeAccount();
      } catch (error) {
        useAlert(this.$t('KNOWLEDGE_CHATBOT.ADD.API.ERROR_MESSAGE'));
      }
    },

    async deleteFile(fileId) {
      const payload = {
        id: this.id,
        file_id: fileId,
      };
      await this.$store.dispatch('chatbot/deleteFile', payload);
      this.initializeAccount();
    },

    updateDirectionView(locale) {
      const isRTLSupported = getLanguageDirection(locale);
      this.updateUISettings({
        rtl_view: isRTLSupported,
      });
    },

    setAttachmentPayload(payload) {
      this.attachedFiles.forEach(attachment => {
        if (this.globalConfig.directUploadsEnabled) {
          payload.files.push(attachment.blobSignedId);
        } else {
          payload.files.push(attachment.resource.file);
        }
      });
    },
    attachFile({ blob, file }) {
      const reader = new FileReader();
      reader.readAsDataURL(file.file);
      reader.onloadend = () => {
        this.attachedFiles.push({
          currentChatId: this.id,
          resource: blob || file,
          isPrivate: this.isPrivate,
          thumb: reader.result,
          blobSignedId: blob ? blob.signed_id : undefined,
        });
      };
    },

    removeAttachment(attachments) {
      this.attachedFiles = attachments;
    },
  },
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('KNOWLEDGE_CHATBOT.LOADING')"
    :no-records-found="!files.length"
    :no-records-message="$t('KNOWLEDGE_CHATBOT.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('KNOWLEDGE_CHATBOT.HEADER')"
        :description="$t('KNOWLEDGE_CHATBOT.DESCRIPTION')"
        feature-name="knowledge"
      />

      <p>
        <b>{{ $t('CHATBOT_SETTINGS.DOCUMENT.SUBTITLE_UPLOAD') }}</b>
      </p>

      <FileUpload
        input-id="newConversationAttachment"
        :size="4096 * 4096"
        :accept="allowedFileTypes"
        multiple
        drop
        :drop-directory="false"
        :data="{
          direct_upload_url: '/rails/active_storage/direct_uploads',
          direct_upload: true,
        }"
        @input-file="onFileUpload"
      >
        <woot-button
          class-names="button--upload"
          icon="attach"
          emoji="📎"
          color-scheme="secondary"
          variant="smooth"
          size="small"
        >
          {{ $t('CHATBOT_SETTINGS.DOCUMENT.BUTTON_UPLOAD') }}
        </woot-button>
        <span
          class="text-slate-500 ltr:ml-1 rtl:mr-1 font-medium text-xs dark:text-slate-400"
        >
          {{ $t('NEW_CONVERSATION.FORM.ATTACHMENTS.HELP_TEXT') }}
        </span>
      </FileUpload>

      <div v-if="hasAttachments" class="max-h-20 overflow-y-auto mb-4 mt-1.5">
        <AttachmentPreview
          class="[&>.preview-item]:dark:bg-slate-700 flex-row flex-wrap gap-x-3 gap-y-1"
          :attachments="attachedFiles"
          @remove-attachment="removeAttachment"
        />
      </div>

      <div v-if="attachedFiles.length > 0" class="mt-auto w-80 mb-5">
        <woot-button
          size="expanded"
          color-scheme="success"
          icon="upload"
          class="w-full"
          @click="updateDocument()"
        >
          {{ $t('KNOWLEDGE_CHATBOT.UPLOAD_BUTTON_TEXT') }}
          <Spinner
            v-if="loadingButton"
            class="ml-2"
            :color-scheme="spinnerClass"
          />
        </woot-button>
      </div>

      <hr />
    </template>

    <template #body>
      <table class="divide-y divide-slate-75 dark:divide-slate-700">
        <thead>
          <th
            v-for="thHeader in $t('KNOWLEDGE_CHATBOT.LIST.TABLE_HEADER')"
            :key="thHeader"
            class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-slate-700 dark:text-slate-300"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody
          class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300"
        >
          <tr v-for="(file, index) in files" :key="index" :file="file">
            <td class="py-4 pr-4 break-all whitespace-nowrap">
              {{ file.name }}
            </td>
            <td class="py-4 pr-4 break-all whitespace-nowrap">
              <woot-button
                v-tooltip.top="$t('CHATBOT_SETTINGS.DOCUMENT.ICON_DELETE_FILE')"
                variant="smooth"
                color-scheme="alert"
                size="tiny"
                icon="dismiss-circle"
                class-names="grey-btn"
                @click="openDeletePopup(file, index)"
              />
            </td>
          </tr>
        </tbody>
      </table>

      <woot-delete-modal
        :show.sync="showDeleteConfirmationPopup"
        :on-close="closeDeletePopup"
        :on-confirm="confirmDeletion"
        :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
        :message="$t('MACROS.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="$t('MACROS.DELETE.CONFIRM.YES')"
        :reject-text="$t('MACROS.DELETE.CONFIRM.NO')"
      />
    </template>
  </SettingsLayout>
</template>

<style lang="scss">
.file-uploads {
  text-align: left !important;
}

.gap-10 {
  gap: 15px !important;
}

hr {
  margin-top: 0px !important;
  margin-bottom: 0px !important;
}

.chatbot-qr {
  height: 200px;
}

.chatbot-textarea {
  height: 250px;
}
</style>
