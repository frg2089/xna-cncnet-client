using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Http.Json;
using System.Threading;
using System.Threading.Tasks;

using ClientCore;

namespace DTAClient.Domain.Multiplayer.CnCNet
{
    /// <summary>
    /// A class for updating of the CnCNet game/player count.
    /// </summary>
    public static class CnCNetPlayerCountTask
    {
        private const string StatusUrl = "http://api.cncnet.org/status";

        public static int PlayerCount { get; private set; }

        private static int REFRESH_INTERVAL = 60000; // 1 minute

        internal static event EventHandler<PlayerCountEventArgs> CnCNetGameCountUpdated;

        private static string cncnetLiveStatusIdentifier;

        public static async Task InitializeServiceAsync(CancellationToken cancellationToken)
        {
            cncnetLiveStatusIdentifier = ClientConfiguration.Instance.CnCNetLiveStatusIdentifier;
            PlayerCount = await GetCnCNetPlayerCountAsync(cancellationToken);

            CnCNetGameCountUpdated?.Invoke(null, new PlayerCountEventArgs(PlayerCount));

            _ = RunServiceAsync(cancellationToken);
        }

        private static async Task RunServiceAsync(CancellationToken cancellationToken)
        {
            var waitHandle = cancellationToken.WaitHandle;

            while (true)
            {
                if (waitHandle.WaitOne(REFRESH_INTERVAL))
                {
                    // Cancellation signaled
                    return;
                }
                else
                {
                    var count = await GetCnCNetPlayerCountAsync(cancellationToken);
                    CnCNetGameCountUpdated?.Invoke(null, new PlayerCountEventArgs(count));
                }
            }
        }

        private static async Task<int> GetCnCNetPlayerCountAsync(CancellationToken cancellationToken)
        {
            var info = await ProgramConstants.SharedClient.GetFromJsonAsync<Dictionary<string, int>>(StatusUrl, cancellationToken);
            if (!info.TryGetValue(cncnetLiveStatusIdentifier, out var numGames))
                numGames = -1;

            return numGames;
        }
    }

    internal class PlayerCountEventArgs : EventArgs
    {
        public PlayerCountEventArgs(int playerCount)
        {
            PlayerCount = playerCount;
        }

        public int PlayerCount { get; set; }
    }
}
