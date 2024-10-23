import { required } from '@vuelidate/validators';

export const validLabelCharacters = (str = '') => !!str && !str.includes(' ');

export const getLabelTitleErrorMessage = validation => {
  let errorMessage = '';
  if (!validation.code_function.$error) {
    errorMessage = '';
  }
  if (!validation.name.$error) {
    errorMessage = '';
  }
  return errorMessage;
};

export default {
  code_function: {
    required,
  },
  name: {
    required,
  },
  chatbot: {
    required,
  },
};
