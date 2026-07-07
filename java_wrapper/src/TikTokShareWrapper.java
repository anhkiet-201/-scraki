import android.content.ClipData;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.IBinder;

import java.io.PrintStream;
import java.lang.reflect.Method;
import java.util.ArrayList;

public class TikTokShareWrapper {
    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("Sử dụng: TikTokShareWrapper <target_package> <uri_list_comma_separated> [mime_type]");
            System.exit(1);
        }

        String targetPackage = args[0];
        String[] uriStrings = args[1].split(",");
        String mimeType = (args.length > 2) ? args[2] : "image/*";

        ArrayList<Uri> uriList = new ArrayList<>();
        for (String uriString : uriStrings) {
            uriString = uriString.trim();
            if (!uriString.isEmpty()) {
                uriList.add(Uri.parse(uriString));
            }
        }

        if (uriList.isEmpty()) {
            System.err.println("ERROR: Danh sách URI trống.");
            System.exit(1);
        }

        try {
            Intent intent = new Intent("android.intent.action.SEND_MULTIPLE");
            intent.setPackage(targetPackage);
            intent.setType(mimeType);
            intent.putParcelableArrayListExtra("android.intent.extra.STREAM", uriList);
            intent.putExtra("android.intent.extra.TEXT", "");
            
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

            ClipData clipData = ClipData.newRawUri("Shared Media", uriList.get(0));
            for (int i = 1; i < uriList.size(); i++) {
                clipData.addItem(new ClipData.Item(uriList.get(i)));
            }
            intent.setClipData(clipData);

            Class<?> activityManagerNativeClass = Class.forName("android.app.ActivityManagerNative");
            Method getDefaultMethod = activityManagerNativeClass.getMethod("getDefault");
            Object iActivityManager = getDefaultMethod.invoke(null);

            Class<?> iApplicationThreadClass = Class.forName("android.app.IApplicationThread");
            Class<?> profilerInfoClass = Class.forName("android.app.ProfilerInfo");

            Method startActivityAsUserMethod = iActivityManager.getClass().getMethod(
                    "startActivityAsUser",
                    iApplicationThreadClass,
                    String.class,
                    Intent.class,
                    String.class,
                    IBinder.class,
                    String.class,
                    int.class,
                    int.class,
                    profilerInfoClass,
                    Bundle.class,
                    int.class
            );

            startActivityAsUserMethod.invoke(
                    iActivityManager,
                    null,
                    "com.android.shell",
                    intent,
                    intent.getType(),
                    null,
                    null,
                    0,
                    0,
                    null,
                    null,
                    -2
            );

            System.out.println("SUCCESS: Intent sent from shell context.");
        } catch (Exception e) {
            System.err.println("ERROR: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}

