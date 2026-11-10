from pathlib import Path
import re
p = Path('decoded/AndroidManifest.xml')
t = p.read_text(encoding='utf-8', errors='ignore')
provider = '''
        <provider android:name="com.studio27.melonmod.MelonDocumentsProvider" android:authorities="com.studio27.MelonPlayground.documents" android:exported="true" android:grantUriPermissions="true" android:permission="android.permission.MANAGE_DOCUMENTS" android:enabled="true">
            <intent-filter>
                <action android:name="android.content.action.DOCUMENTS_PROVIDER" />
            </intent-filter>
        </provider>
'''
if 'MelonDocumentsProvider' not in t:
    m = re.search(r'</application\s*>', t, flags=re.I)
    t = t[: m.start()] + provider + '\n    ' + t[m.start() :]
    p.write_text(t, encoding='utf-8')
print('manifest ok')
