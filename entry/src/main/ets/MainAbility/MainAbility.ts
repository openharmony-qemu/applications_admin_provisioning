/*
 * Copyright (c) 2022-2023 Huawei Device Co., Ltd.
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

import UIAbility from '@ohos.app.ability.UIAbility';
import Logger from '../common/logger';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

const TAG = 'MainAbility';

export default class MainAbility extends UIAbility {
  private localStorage: LocalStorage = new LocalStorage();
  private windowStage: window.WindowStage | undefined = undefined;

  onCreate(want: Want): void {
    Logger.info(TAG, 'onCreate');
    this.localStorage.setOrCreate('adminProvisioningWant', want);
  }

  onDestroy(): void {
    Logger.info(TAG, 'onDestroy');
  }

  onNewWant(want: Want): void {
    this.localStorage.setOrCreate('adminProvisioningWant', want);
    this.loadPage();
  }

  private loadPage(): void {
    this.windowStage?.loadContent('pages/applicationInfo', this.localStorage).catch(error => {
      Logger.info(TAG, 'Provisioning page could not load: ' + error?.message);
    });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    Logger.info(TAG, 'onWindowStageCreate');
    this.windowStage = windowStage;
    this.loadPage();
  }

  onWindowStageDestroy(): void {
    this.windowStage = undefined;
    // Main window is destroyed, release UI related resources
    Logger.info(TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    Logger.info(TAG, 'onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    Logger.info(TAG, 'onBackground');
  }
};
