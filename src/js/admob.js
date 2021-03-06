import exec from 'cordova/exec'

import { translateOptions } from './utils'

import { Banner } from './banner'
import { Interstitial } from './interstitial'

/**
 * @type {Banner}
 * @since 0.6
 * @emits {admob.banner.events.LOAD}
 * @emits {admob.banner.events.LOAD_FAIL}
 * @emits {admob.banner.events.OPEN}
 * @emits {admob.banner.events.CLOSE}
 * @example
 * admob.banner.config({
 *  id: 'ca-app-pub-xxx/xxx',
 * })
 *
 * // Create banner
 * admob.banner.prepare()
 *
 * // Show the banner
 * admob.banner.show()
 *
 * // Hide the banner
 * admob.banner.hide()
 *
 * // Remove the banner
 * admob.banner.remove()
 */
export const banner = new Banner()

/**
 * @type {Interstitial}
 * @since 0.6
 * @emits {admob.interstitial.events.LOAD}
 * @emits {admob.interstitial.events.LOAD_FAIL}
 * @emits {admob.interstitial.events.OPEN}
 * @emits {admob.interstitial.events.CLOSE}
 * @example
 * admob.interstitial.config({
 *  id: 'ca-app-pub-xxx/xxx',
 * })
 *
 * admob.interstitial.prepare()
 *
 * admob.interstitial.show()
 *
 * admob.interstitial.ready()
 */
export const interstitial = new Interstitial()

// Old APIs

/**
 * Set options.
 *
 * @deprecated since version 0.6
 * @param {Object} options
 * @param {string} options.publisherId
 * @param {string} options.interstitialAdId
 *
 * @param {boolean} [options.bannerAtTop=false]
 * Set to true, to put banner at top.
 * @param {boolean} [options.overlap=true]
 * Set to true, to allow banner overlap webview.
 * @param {boolean} [options.offsetTopBar=false]
 * Set to true to avoid ios7 status bar overlap.
 * @param {boolean} [options.isTesting=false]
 * Receiving test ad.
 * @param {boolean} [options.autoShow=true]
 * Auto show interstitial ad when loaded.
 *
 * @param {boolean|null} [options.forChild=null]
 * Default is not calling `tagForChildDirectedTreatment`.
 * Set to "true" for `tagForChildDirectedTreatment(true)`.
 * Set to "false" for `tagForChildDirectedTreatment(false)`.
 *
 * @param {boolean|null} [options.forFamily=null]
 * Android-only.
 * Default is not calling `setIsDesignedForFamilies`.
 * Set to "true" for `setIsDesignedForFamilies(true)`.
 * Set to "false" for `setIsDesignedForFamilies(false)`.
 *
 * @param {function()} [successCallback]
 * @param {function()} [failureCallback]
 */
export function setOptions(options, successCallback, failureCallback) {
  if (typeof options === 'object') {
    Object.keys(options).forEach(k => {
      switch (k) {
        case 'publisherId':
          banner._config.id = options[k]
          break
        case 'bannerAtTop':
        case 'overlap':
        case 'offsetTopBar':
          banner._config[k] = options[k]
          break
        case 'interstitialAdId':
          interstitial._config.id = options[k]
          break
        case 'isTesting':
        case 'autoShow':
          banner._config[k] = options[k]
          interstitial._config[k] = options[k]
          break
        default:
      }
    })
    exec(successCallback, failureCallback, 'AdMob', 'setOptions', [
      translateOptions(options),
    ])
  } else if (typeof failureCallback === 'function') {
    failureCallback('options should be specified.')
  }
}

/**
 * Ad sizes.
 * @constant
 * @type {BANNER_SIZE}
 * @deprecated since version 0.6
 */
export const AD_SIZE = Banner.sizes

/**
 * @deprecated since version 3.1
 */
export function userMessagingPlatform() {
  return new Promise((resolve, reject) => {
    exec(resolve, reject, 'AdMob', 'userMessagingPlatform', [])
  })
}

/**
 * @deprecated since version 3.1
 */
export function getTrackingStatus() {
  return new Promise((resolve, reject) => {
    exec(resolve, reject, 'AdMob', 'getTrackingStatus', [])
  })
}

/**
 * @deprecated since version 3.1
 */
export function trackingStatusForm() {
  return new Promise((resolve, reject) => {
    exec(resolve, reject, 'AdMob', 'trackingStatusForm', [])
  })
}
