package top.modpotato.PluginNameHere;

import org.bukkit.plugin.java.JavaPlugin;

/**
 * Main plugin class for PluginNameHere
 */
public class Main extends JavaPlugin {
    private static boolean isFolia;

    @Override
    public void onEnable() {
        try {
            isFolia = checkFolia();
            getLogger().info("Running on " + (isFolia ? "Folia" : "Paper") + " server");
            getLogger().info("PluginNameHere has been enabled!");
        } catch (Exception e) {
            getLogger().severe("Error enabling PluginNameHere: " + e.getMessage());
            e.printStackTrace();
            getServer().getPluginManager().disablePlugin(this);
        }
    }

    @Override
    public void onDisable() {
        try {
            getLogger().info("PluginNameHere has been disabled!");
        } catch (Exception e) {
            getLogger().severe("Error disabling PluginNameHere: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Checks if the server is running on Folia
     * @return true if running on Folia, false otherwise
     */
    private boolean checkFolia() {
        try {
            Class.forName("io.papermc.paper.threadedregions.RegionizedServer");
            return true;
        } catch (ClassNotFoundException e) {
            return false;
        }
    }
}