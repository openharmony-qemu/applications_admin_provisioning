/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import edmEnterpriseDeviceManager from '@ohos.enterprise.adminManager';
import router from '@ohos.router';
import appDetailData from '../common/appManagement/appDetailData'
import baseData from '../common/baseData';
import entryComponent from './component/entryComponent'
import headComponent from './component/headComponent';
import logger from '../common/logger'
import permissionListComponent from './component/permissionListComponent';
import utils from '../common/utils'
import { AppPermission, MyApplicationInfo } from '../common/myApplicationInfo'
import Want from '@ohos.app.ability.Want';
import adminManager from '@ohos.enterprise.adminManager';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';

const TAG = 'ApplicationInfo';

@Entry({ useSharedStorage: true })
@Component
struct ApplicationInfo {
  @State applicationInfo: MyApplicationInfo = {
    appIcon: '',
    appTitle: '',
    appBundleName: '',
    appPermissionList: []
  };
  @State isShowActive: boolean = false;
  @State isEnableButton: boolean = false;
  @State operationPending: boolean = false;
  @State operationError: string = '';
  private pageActive: boolean = true;
  private requestReady: boolean = false;
  private request: Want | undefined = undefined;
  private elementNameVal: Want = { bundleName: '', abilityName: '' };
  private enterInfo: adminManager.EnterpriseInfo = { name: '', description: '' };
  @State isAdminType: number = 0;
  @State deviceAdminActive: string = '';
  @State deviceAdminDisActive: string = '';
  @State enterpriseName: string = '';
  @State enterpriseDescription: string = '';
  private storage = LocalStorage.getShared();

  build() {
    Column() {
      if (this.operationError.length > 0) {
        Text(this.operationError).fontColor(Color.Red).id('admin-provisioning-error');
      }
      Column() {
        GridContainer({
          columns: utils.isLargeDevice(),
          sizeType: SizeType.Auto,
          gutter: '12vp',
          margin: '12vp'
        }) {
          Column() {
            headComponent({ headName: $r('app.string.adminprovisioning') });

            Row() {
              entryComponent({
                appIcon: this.applicationInfo.appIcon,
                appTitle: this.applicationInfo.appTitle,
              })
            }

            Column() {
              Text(this.enterpriseName)
                .height($r('app.float.wh_value_21'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontSize($r('app.float.font_16'))
                .fontWeight(FontWeight.Medium)
                .textAlign(TextAlign.Start)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({
                  left: $r('app.float.wh_value_36'),
                  top: $r('app.float.wh_value_12'),
                });

              Text(this.enterpriseDescription)
                .height($r('app.float.wh_value_19'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .fontSize($r('app.float.font_14'))
                .fontWeight(FontWeight.Regular)
                .textAlign(TextAlign.Start)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({
                  left: $r('app.float.wh_value_36'),
                  top: $r('app.float.wh_value_2'),
                });
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .align(Alignment.Start)

            Column() {
              Text(this.isShowActive ? this.deviceAdminActive : this.deviceAdminDisActive)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontSize($r('app.float.font_16'))
                .fontWeight(FontWeight.Medium)
                .textAlign(TextAlign.Start)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({
                  left: $r('app.float.wh_value_36'),
                  top: $r('app.float.wh_value_24'),
                });

              List() {
                ForEach(this.applicationInfo.appPermissionList, (item: AppPermission) => {
                  ListItem() {
                    permissionListComponent({
                      permissionName: item.permissionLabel,
                      permissionDescription: item.permissionDescription,
                    });
                  }
                }, (item: AppPermission) => JSON.stringify(item));
              }
            }
            .alignItems(HorizontalAlign.Start)
            .align(Alignment.Start)
          }
          .useSizeType({
            xs: { span: 8, offset: 0 }, sm: { span: 8, offset: 0 },
            md: { span: 8, offset: 0 }, lg: { span: 8, offset: 2 }
          })
        }
      }
      .layoutWeight(1)

      Column() {
        GridContainer({
          columns: utils.isLargeDevice(),
          sizeType: SizeType.Auto,
          gutter: '12vp',
          margin: '12vp'
        }) {
          Row() {
            Row()
              .useSizeType({
                xs: { span: 1, offset: 0 }, sm: { span: 1, offset: 0 },
                md: { span: 1, offset: 0 }, lg: { span: 3, offset: 0 }
              })

            Button() {
              Text(this.isShowActive ? $r('app.string.deActivate') : $r('app.string.activation'))
                .opacity(this.isEnableButton ? 1 : 0.38)
                .fontSize($r('sys.float.ohos_id_text_size_button1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
            }
            .enabled(this.requestReady && this.isEnableButton && !this.operationPending)
            .id('admin-provisioning-activate')
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .height($r('app.float.button_height'))
            .margin({
              right: $r('app.float.wh_value_6'),
              bottom: $r('app.float.wh_value_24')
            })
            .onClick(() => {
              logger.info(TAG, 'button active:' + this.isShowActive);
              this.activateAdmin(this.isAdminType);
            })
            .useSizeType({
              xs: { span: 3, offset: 1 }, sm: { span: 3, offset: 1 },
              md: { span: 3, offset: 1 }, lg: { span: 3, offset: 3 }
            })

            Button() {
              Text($r('app.string.cancel'))
                .fontSize($r('sys.float.ohos_id_text_size_button1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
            }
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .height($r('app.float.button_height'))
            .margin({
              left: $r('app.float.wh_value_6'),
              bottom: $r('app.float.wh_value_24')
            })
            .enabled(!this.operationPending)
            .id('admin-provisioning-cancel')
            .onClick(() => {
              logger.info(TAG, 'button cancel in isShowActive:' + this.isShowActive);
              this.cancelAdmin();
            })
            .useSizeType({
              xs: { span: 3, offset: 4 }, sm: { span: 3, offset: 4 },
              md: { span: 3, offset: 4 }, lg: { span: 3, offset: 6 }
            })

            Row()
              .useSizeType({
                xs: { span: 1, offset: 7 }, sm: { span: 1, offset: 7 },
                md: { span: 1, offset: 7 }, lg: { span: 3, offset: 9 }
              })
          }
          .justifyContent(FlexAlign.Center)
        }
      }.width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }

  async aboutToAppear(): Promise<void> {
    this.pageActive = true;
    this.requestReady = false;
    this.request = this.storage.get<Want>('adminProvisioningWant');
    this.elementNameVal = {
      abilityName: '',
      bundleName: '',
    };

    this.enterInfo = {
      name: '',
      description: '',
    };

    logger.info(TAG, 'aboutToAppear in');
    try {
      await this.getCheckAbilityList(this.applicationInfo);
    } catch (error) {
      this.isEnableButton = false;
      this.operationError = `加载失败：${error?.message ?? '服务不可用'}`;
    }
    logger.info(TAG, 'aboutToAppear out');
  }

  aboutToDisappear(): void {
    this.pageActive = false;
    logger.info(TAG, 'aboutToDisappear');
  }

  async onPageShow(): Promise<void> {
    if (!this.requestReady || !this.isCurrentRequest()) {
      return;
    }
    try {
      await this.isAdminActive();
    } catch (error) {
      this.isEnableButton = false;
      this.operationError = `查询管理状态失败：${error?.message ?? '服务不可用'}`;
      logger.error(TAG, this.operationError);
    }
  }

  onPageHide() {
    logger.info(TAG, 'onPageHide');
  }

  private isCurrentRequest(): boolean {
    return this.pageActive && this.storage.get<Want>('adminProvisioningWant') === this.request;
  }

  async cancelAdmin(): Promise<void> {
    if (!this.operationPending && this.isCurrentRequest()) {
      try {
        await appDetailData.terminateAbilityPage();
      } catch (error) {
        this.operationError = `取消失败：${error?.message ?? '界面退出失败'}`;
      }
    }
  }

  onBackPress(): boolean {
    this.cancelAdmin();
    return true;
  }

  async isAdminActive() {
    let wantTemp: Want = {
      bundleName: this.elementNameVal.bundleName,
      abilityName: this.elementNameVal.abilityName,
    };
    let retAppState: boolean;
    let retSuperState: boolean;
    logger.info(TAG, 'isAdminActive this.elementNameVal.bundleName=' + this.elementNameVal.bundleName +
    ' | this.elementNameVal.abilityName=' + this.elementNameVal.abilityName);
    if (this.elementNameVal.bundleName === baseData.EMPTY_STR || this.elementNameVal.abilityName === baseData.EMPTY_STR) {
      logger.info(TAG, 'isAdminActive this.elementNameVal is null');
      return;
    }

    retAppState = await edmEnterpriseDeviceManager.isAdminEnabled(wantTemp);
    const name: string | undefined = wantTemp.bundleName;
    if (typeof name !== 'string' || name.length === 0) {
      throw new Error('设备管理应用名称缺失');
    }
    retSuperState = await edmEnterpriseDeviceManager.isSuperAdmin(name);
    if (!this.isCurrentRequest()) {
      return;
    }
    if (!retAppState) {
      this.isShowActive = false;
      this.isEnableButton = true;
    } else {
      if (retSuperState) {
        this.isEnableButton = false;
      } else {
        this.isEnableButton = true;
      }
      this.isShowActive = true;
    }
    logger.info(TAG, 'isAdminActive retAppState:' + retAppState + ' | retSuperState:' + retSuperState);
  }

  async activateAdmin(adminType: adminManager.AdminType): Promise<void> {
    if (this.operationPending || !this.requestReady || !this.isCurrentRequest()) {
      return;
    }
    this.operationPending = true;
    this.operationError = '';
    try {
      const want: Want = {
        bundleName: this.elementNameVal.bundleName,
        abilityName: this.elementNameVal.abilityName
      };
      const enterprise: adminManager.EnterpriseInfo = { name: this.enterInfo.name, description: this.enterInfo.description };
      if (!want.bundleName || !want.abilityName) {
        throw new Error('请选择有效的设备管理应用');
      }
      await this.isAdminActive();
      if (!this.isCurrentRequest()) {
        return;
      }
      if (!this.isEnableButton) {
        throw new Error('当前设备管理员不允许执行此操作');
      }
      const enable: boolean = !this.isShowActive;
      if (enable) {
        if (adminType !== edmEnterpriseDeviceManager.AdminType.ADMIN_TYPE_NORMAL) {
          throw new Error('此页面只支持普通设备管理员激活');
        }
        await edmEnterpriseDeviceManager.enableAdmin(want,
          enterprise,
          edmEnterpriseDeviceManager.AdminType.ADMIN_TYPE_NORMAL);
      } else {
        await edmEnterpriseDeviceManager.disableAdmin(want);
      }
      const actual: boolean = await edmEnterpriseDeviceManager.isAdminEnabled(want);
      if (actual !== enable) {
        throw new Error('设备管理服务未确认请求的状态');
      }
      // A new singleton Want may already have replaced this page.
      if (this.isCurrentRequest()) {
        this.isShowActive = actual;
        await appDetailData.terminateAbilityPage();
      }
    } catch (error) {
      this.operationError = `操作失败：${error?.message ?? '设备管理服务不可用'}`;
      logger.error(TAG, this.operationError);
    } finally {
      this.operationPending = false;
    }
  }

  async getSelfResourceVal(resource: Resource) {
    let resMgr = getContext().resourceManager;
    logger.info(TAG, 'getSelfResourceVal in:');
    let value = await resMgr.getString(resource.id);
    logger.info(TAG, 'getSelfResourceVal finish value:' + value);
    if (!utils.isValid(value) || value === baseData.EMPTY_STR) {
      return baseData.EMPTY_STR;
    }
    return value;
  }

  async getAbilityWantVal(appInfo: MyApplicationInfo) {
    logger.info(TAG, 'getAbilityWantVal in:');
    this.storage = LocalStorage.getShared();
    const data: Want | undefined = this.request;
    if (!data || !data.parameters || !this.isCurrentRequest()) {
      throw new Error('无效的设备管理请求');
    }
    const element = data.parameters.elementName as Record<string, string>;
    const enterprise = data.parameters.enterprise as Record<string, string>;
    if (!element || typeof element.bundleName !== 'string' || !element.bundleName ||
        typeof element.abilityName !== 'string' || !element.abilityName ||
        !enterprise || typeof enterprise.name !== 'string' || typeof enterprise.description !== 'string' ||
        (data.parameters.activeType !== adminManager.AdminType.ADMIN_TYPE_NORMAL &&
         data.parameters.activeType !== adminManager.AdminType.ADMIN_TYPE_SUPER)) {
      throw new Error('设备管理应用、类型或企业信息无效');
    }

    this.elementNameVal.abilityName = (data.parameters?.elementName as Record<string, string>).abilityName;
    this.elementNameVal.bundleName = (data.parameters?.elementName as Record<string, string>).bundleName;
    appInfo.appBundleName = (data.parameters?.elementName as Record<string, string>).bundleName;
    this.isAdminType = data.parameters?.activeType as adminManager.AdminType;

    this.enterInfo.name = (data.parameters?.enterprise as Record<string, string>).name.substring(0, baseData.MAX_LEN);
    this.enterInfo.description =
      (data.parameters?.enterprise as Record<string, string>).description.substring(0, baseData.MAX_LEN);
    logger.info(TAG, 'getAbilityWantVal out isAdminTypeVal.admintype:' + this.isAdminType +
    ' enter.name=' + this.enterInfo.name + ' enter.des=' + this.enterInfo.description);
  }

  async getCheckAbilityList(appInfo: MyApplicationInfo) {
    let deviceActiveOne = '';
    let deviceActiveTwo = '';
    let deviceDeactivate = '';
    let getName = '';
    let getDescription = '';
    logger.info(TAG, 'getCheckAbilityList in:');
    await this.getAbilityWantVal(appInfo);

    let ret = await appDetailData.checkAppItem(this.elementNameVal);
    if (!ret) {
      logger.info(TAG, 'aboutToAppear not exist bundleName:' + appInfo.appBundleName);
      throw new Error('未找到有效的设备管理扩展');
    }

    await this.isAdminActive();
    if (!this.isCurrentRequest()) {
      return;
    }

    if (appInfo.appBundleName) {
      await appDetailData.getBundleInfoItem(appInfo.appBundleName, appInfo);
    }
    if (!this.isCurrentRequest()) {
      return;
    }
    try {
      this.deviceAdminActive = getContext()?.resourceManager
        .getStringSync($r('app.string.textApplicationInfoActive').id, `${appInfo.appTitle}`);
      this.deviceAdminDisActive = getContext()?.resourceManager
        .getStringSync($r('app.string.textApplicationInfoInactive').id, `${appInfo.appTitle}`);
    } catch (e) {
      logger.error(TAG, 'getStringSync title err =' + e.message);
    }

    let want: Want = {
      bundleName: this.elementNameVal.bundleName,
      abilityName: this.elementNameVal.abilityName,
    };
    let getEnterInfo: adminManager.EnterpriseInfo = {
      name: '',
      description: '',
    };
    if (this.isShowActive) {
      logger.info(TAG, 'getCheckAbilityList get getEnterInfo');
      getEnterInfo = await edmEnterpriseDeviceManager.getEnterpriseInfo(want);
    }

    if (!this.isCurrentRequest()) {
      return;
    }
    logger.info(TAG, 'getCheckAbilityList start enterpriseName=' + getEnterInfo.name +
    ' enterpriseDescription=' + getEnterInfo.description);
    if (utils.isValid(getEnterInfo.name)) {
      getName = getEnterInfo.name.substring(0, baseData.MAX_LEN);
    }
    if (utils.isValid(getEnterInfo.description)) {
      getDescription = getEnterInfo.description.substring(0, baseData.MAX_LEN);
    }

    try {
      if (this.isShowActive) {
        this.enterpriseName = getContext()?.resourceManager.
          getStringSync($r('app.string.enterprise_name').id, getName);
        this.enterpriseDescription = getContext()?.resourceManager
          .getStringSync($r('app.string.enterprise_description').id, getDescription);
      } else {
        this.enterpriseName = getContext()?.resourceManager
          .getStringSync($r('app.string.enterprise_name').id, this.enterInfo.name);
        this.enterpriseDescription = getContext()?.resourceManager
          .getStringSync($r('app.string.enterprise_description').id, this.enterInfo.description);
      }
    } catch (e) {
      logger.error(TAG, 'getStringSync err =' + e.message);
    }
    this.requestReady = true;
    logger.info(TAG, 'getCheckAbilityList enterpriseName=' + this.enterpriseName + ' enterpriseDescription=' +
    this.enterpriseDescription);
  }
}