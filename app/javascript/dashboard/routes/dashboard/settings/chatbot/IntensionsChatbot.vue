<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConfig } from 'dashboard/composables/useConfig';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import semver from 'semver';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

import FileUpload from 'vue-upload-component';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview';
import { ALLOWED_FILE_TYPES } from 'shared/constants/chatbot';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';

export default {
  name: 'Intensions',
  components: {
    FileUpload,
    AttachmentPreview,
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
      locale: 'es',
      id: '',
      promts: '',
      qr: '',
      email_notify: '',
      status: '',
      type_chatbot_id: '',
      attachedFiles: [],
      files: [],
    };
  },
  validations: {
    promts: {
      required,
    },
    email_notify: {
      required,
    },
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
        const { id, status, promts, qr, email_notify, type_chatbot_id, files } =
          await this.$store.dispatch('chatbot/get');

        this.id = id;
        this.status = status;
        this.promts = promts;
        this.qr = qr;
        this.email_notify = email_notify;
        this.type_chatbot_id = type_chatbot_id;
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

    async updateChatbot() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }
      try {
        const payload = {
          id: this.id,
          status: this.status,
          promts: this.promts,
          qr: this.qr,
          email_business: this.email_business,
          email_notify: this.email_notify,
          type_chatbot_id: this.type_chatbot_id,
        };

        if (this.attachedFiles && this.attachedFiles.length) {
          payload.files = [];
          this.setAttachmentPayload(payload);
        }

        await this.$store.dispatch('chatbot/update', payload);
        this.$root.$i18n.locale = this.locale;
        // this.getAccount(this.id).locale = this.locale;
        // this.updateDirectionView(this.locale);
        this.initializeAccount();
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
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
  <div class="flex-grow flex-shrink min-w-0 p-6 overflow-auto">
    <form v-if="!uiFlags.isFetchingItem" @submit.prevent="updateChatbot">
      <div
        class="flex flex-row p-4 border-b border-slate-25 dark:border-slate-800 flex-[50%]"
      >
        <div
          class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0"
        >
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            {{ $t('CHATBOT_SETTINGS.FORM_GENERAL_SECTION_TITLE') }}
          </h4>
          <p>{{ $t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.NOTE') }}</p>
        </div>
        <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%]">
          <div
            class="flex items-center justify-between w-full gap-2 p-4 border border-solid border-ash-200 rounded-xl mb-5"
          >
            <div class="flex flex-row items-center gap-2">
              <fluent-icon
                icon="alert"
                class="flex-shrink-0 text-ash-900"
                size="18"
              />
              <span class="text-sm text-ash-900">
                {{ $t('CHATBOT_SETTINGS.FORM_STATUS_LABEL') }}
              </span>

              <woot-switch v-model="status" />
            </div>
          </div>

          <label :class="{ error: v$.promts.$error }">
            {{ $t('CHATBOT_SETTINGS.FORM_PROMPT_LABEL') }}
            <textarea
              v-model="promts"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_PROMPT_PLACEHOLDER')"
              rows="10"
              class="chatbot-textarea"
              @blur="v$.promts.$touch"
            />
            <span v-if="v$.promts.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>

          <label :class="{ error: v$.email_notify.$error }">
            {{ $t('CHATBOT_SETTINGS.FORM_EMAIL_NOTIFY') }}
            <input
              v-model="email_notify"
              type="text"
              :placeholder="$t('CHATBOT_SETTINGS.FORM_EMAIL_PLACEHOLDER')"
              @blur="v$.email_notify.$touch"
            />
            <span v-if="v$.email_notify.$error" class="message">
              {{ $t('GENERAL_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <div>
            <label>{{ $t('CHATBOT_SETTINGS.FORM_QR_PLACEHOLDER') }}</label>
            <img :src="qr" class="chatbot-qr" />
          </div>
        </div>
      </div>

      <div
        class="flex flex-row p-4 border-b border-slate-25 dark:border-slate-800 flex-[50%]"
      >
        <div
          class="flex-grow-0 flex-shrink-0 flex-[25%] min-w-0 py-4 pr-6 pl-0"
        >
          <h4 class="text-lg font-medium text-black-900 dark:text-slate-200">
            {{ $t('CHATBOT_SETTINGS.DOCUMENT.TITLE') }}
          </h4>
        </div>

        <div class="p-4 flex-grow-0 flex-shrink-0 flex-[50%]">
          <div class="">
            <p>
              <b>{{ $t('CHATBOT_SETTINGS.DOCUMENT.SUBTITLE_UPLOAD') }}</b>
            </p>
            <hr />
            <p class="mb-0 text-sm mt-5">
              {{ $t('CHATBOT_SETTINGS.DOCUMENT.PARAGRAPH') }}
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
              class="mt-10"
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

            <div
              v-if="hasAttachments"
              class="max-h-20 overflow-y-auto mb-4 mt-1.5"
            >
              <AttachmentPreview
                class="[&>.preview-item]:dark:bg-slate-700 flex-row flex-wrap gap-x-3 gap-y-1"
                :attachments="attachedFiles"
                @remove-attachment="removeAttachment"
              />
            </div>
          </div>

          <div v-if="files.length > 0" class="mt-10">
            <p>
              <b>{{ $t('CHATBOT_SETTINGS.DOCUMENT.SUBTITLE_LOAD') }}</b>
            </p>
            <hr />

            <table class="woot-table mt-10">
              <tr v-for="(file, index) in files" :key="index" :file="file">
                <td>{{ file.name }}</td>
                <td>
                  <woot-button
                    v-tooltip.top="
                      $t('CHATBOT_SETTINGS.DOCUMENT.ICON_DELETE_FILE')
                    "
                    variant="smooth"
                    color-scheme="alert"
                    size="tiny"
                    icon="dismiss-circle"
                    class-names="grey-btn"
                    @click="openDeletePopup(file, index)"
                  />
                </td>
              </tr>
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
          </div>
        </div>
      </div>

      <woot-submit-button
        class="button nice success button--fixed-top"
        :button-text="$t('GENERAL_SETTINGS.SUBMIT')"
        :loading="isUpdating"
      />
    </form>

    <woot-loading-state v-if="uiFlags.isFetchingItem" />
  </div>
</template>

<style lang="scss">
.chatbot-qr {
  height: 200px;
}

.chatbot-textarea {
  height: 250px;
}
</style>
