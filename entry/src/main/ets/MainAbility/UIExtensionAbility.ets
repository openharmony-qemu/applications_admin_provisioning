/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import logger from '../common/logger';
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import configPolicy from '@ohos.configPolicy';
import fs from '@ohos.file.fs';
import adminManager from '@ohos.enterprise.adminManager';
import { BusinessError } from '@ohos.base';
import baseData from '../common/baseData';

const TAG = 'AutoDeployAbility';

interface ProvisionAdmin {
  admin: Want;
  admin_type: string;
}
interface ProvisionEnterprise {
  organization_name: string;
  description: string;
}
interface ProvisionConfig {
  admin_info: ProvisionAdmin[];
  enterprise_info: ProvisionEnterprise;
}

export default class AutoDeployAbility extends UIExtensionAbility {
  private sessions: Set<UIExtensionContentSession> = new Set();

  async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
    if (this.sessions.has(session)) {
      return;
    }
    this.sessions.add(session);
    const storage: LocalStorage = new LocalStorage();
    try {
      const path: string = await configPolicy.getOneCfgFile('etc/edm/edm_provision_config.json');
      const config: ProvisionConfig = JSON.parse(fs.readTextSync(path)) as ProvisionConfig;
      if (!config || !Array.isArray(config.admin_info) || config.admin_info.length === 0 ||
          !config.admin_info[0] || !config.admin_info[0].admin ||
          typeof config.admin_info[0].admin.bundleName !== 'string' || !config.admin_info[0].admin.bundleName ||
          typeof config.admin_info[0].admin.abilityName !== 'string' || !config.admin_info[0].admin.abilityName ||
          config.admin_info[0].admin_type !== 'SDA' || !config.enterprise_info ||
          typeof config.enterprise_info.organization_name !== 'string' ||
          typeof config.enterprise_info.description !== 'string') {
        throw new Error('Invalid enterprise provisioning configuration');
      }
      if (!this.sessions.has(session)) {
        return;
      }
      storage.setOrCreate('adminInfo', config.admin_info[0].admin);
      storage.setOrCreate('enterpriseInfo', {
        name: config.enterprise_info.organization_name,
        description: config.enterprise_info.description
      } as adminManager.EnterpriseInfo);
      storage.setOrCreate('adminType', adminManager.AdminType.ADMIN_TYPE_SUPER);
      storage.setOrCreate('session', session);
      await session.loadContent('pages/custProvisioning/custProvisioning', storage);
    } catch (error) {
      logger.error(TAG, `Provisioning configuration/page failed: ${(error as BusinessError).message}`);
      if (this.sessions.has(session)) {
        try {
          await session.terminateSelfWithResult({ resultCode: baseData.ENABLE_ADMIN_FAILED });
        } catch (deliveryError) {
          logger.error(TAG, `Cannot deliver provisioning failure: ${(deliveryError as BusinessError).message}`);
        }
      }
    }
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    this.sessions.delete(session);
  }

  onDestroy(): void {
    this.sessions.clear();
  }
}
