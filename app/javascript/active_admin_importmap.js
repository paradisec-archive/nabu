// import 'active_admin_importmap/base';
// Below is the contents of the above with jquery fiexes

import 'jquery'
import 'jquery-ui' // FIX We use this instead of the individual imports
import 'jquery-ujs'

import 'active_admin_importmap/ext/jquery'
import 'active_admin_importmap/ext/jquery-ui'
import 'active_admin_importmap/initializers/batch-actions'
import 'active_admin_importmap/initializers/checkbox-toggler'
import 'active_admin_importmap/initializers/datepicker'
import 'active_admin_importmap/initializers/dropdown-menu'
import 'active_admin_importmap/initializers/filters'
import 'active_admin_importmap/initializers/has-many'
import 'active_admin_importmap/initializers/per-page'
import 'active_admin_importmap/initializers/table-checkbox-toggler'
import 'active_admin_importmap/initializers/tabs'

import ModalDialog from 'active_admin_importmap/lib/modal-dialog';

function modal_dialog(message, inputs, callback) {
  console.warn('ActiveAdmin.modal_dialog is deprecated in favor of ActiveAdmin.ModalDialog, please update usage.');
  return ModalDialog(message, inputs, callback);
}

export { ModalDialog, modal_dialog };
