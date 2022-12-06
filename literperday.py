import numpy as np
import matplotlib.pyplot as plt

#start = '/home/sanderjelleoneil/Kenya12/'

with open('cropped_monthly.npy','rb') as fil:
    
    ar = np.load(fil)

print(ar.shape)
ar = np.swapaxes(ar,1,2)

ar = np.flip(ar,1)

SMALL_SIZE = 25
MEDIUM_SIZE = 30
BIGGER_SIZE = 40

plt.rc('font', size=SMALL_SIZE)          # controls default text sizes
plt.rc('axes', titlesize=SMALL_SIZE)     # fontsize of the axes title
plt.rc('axes', labelsize=MEDIUM_SIZE)    # fontsize of the x and y labels
plt.rc('xtick', labelsize=SMALL_SIZE)    # fontsize of the tick labels
plt.rc('ytick', labelsize=SMALL_SIZE)    # fontsize of the tick labels
plt.rc('legend', fontsize=SMALL_SIZE)    # legend fontsize
plt.rc('figure', titlesize=BIGGER_SIZE)  # fontsize of the figure title


fig, axs = plt.subplots(3, 4,figsize=(20, 7))


# import shapefile as shp  # Requires the pyshp package


months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']



ar = ar/360*360*24*10

mi = np.min(ar)
ma = np.max(ar)



import geopandas as gdp

# sf = shp.Reader("gadm41_KEN_0.shp")
map_df = gdp.read_file("gadm41_KEN_0.shp")

map_df.head()


for x in range(0,12):
    
    #plt.figure(figsize=(20, 7))

    im = axs[x//4,x%4].imshow(ar[x],extent = (32.04999924, 43.04999924,-5.94999981, 6.05000019),vmin = mi, vmax = ma,cmap='RdBu')
    
    # axs[x//4,x%4].plot(X,Y)
    
    map_df.boundary.plot(ax = axs[x//4,x%4])
    
    # for s in kenyashapes:
    #     axs[x//4,x%4].plot(s[0],s[1])
    axs[x//4,x%4].set_title(months[x])
    
fig.subplots_adjust(right=0.85,left = 0,top=0.97,bottom=0.03)
cbar_ax = fig.add_axes([0.9, 0.15, 0.02, 0.7])
cbar = fig.colorbar(im, cax=cbar_ax,label = 'Liters of water/Day in a m^2 collecter')

#cbar_ax.annotate('The UN suggests \n at least 50 liters \n per day per person',xy = (0,60),horizontalalignment='right', )

#plt.show()




fig2 = plt.figure("Months of consistent water")

ax2 = fig2.add_axes([0.05,.05,.90,.90])

initialdailywater = 200



arm = 1/ar*200

arm = np.max(arm,0)

orig_map=plt.cm.get_cmap('RdBu')
  
# reversing the original colormap using reversed() function
reversed_map = orig_map.reversed()

month_tot = ax2.imshow(arm,extent = (32.04999924, 43.04999924,-5.94999981, 6.05000019),cmap=reversed_map,interpolation='none',vmin = 0, vmax = 150,)


#plt.title('\nMonths of Consistent Water for Family of Five\n ',fontsize=44)


map_df.boundary.plot(ax=ax2,edgecolor='green')

    
#fig2.subplots_adjust(right=0.95,bottom = .05,top = .95)
cbar_ax = fig2.add_axes([0.9, 0.15, 0.02, 0.7])
cbar = fig2.colorbar(month_tot, cax=cbar_ax,label = 'Required Area of Collector',)



from matplotlib.widgets import Slider, Button


areaax = fig2.add_axes([0.05, 0.15, 0.0325, 0.7])
areasl = Slider(
    ax=areaax,
    label='Water (L)',
    valmin=0.1,
    valmax=500,
    valinit=initialdailywater,
    orientation="vertical"
)


def update(val):
    

    arm = 1/ar*val
    
    arm = np.sum(arm,0)
    
    month_tot.set_data(arm)
    
    plt.draw()
    


# register the update function with each slider
areasl.on_changed(update)

fig3 = plt.figure()

# create some data to plot
months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def lerp(x1, x2, t):
    x = (t - x1)/(x1-x2)
    
    
    return (x)


coords = [
["Nairobi",-1.2864,36.8172],
["Meru",0.0500,37.6500],
["Mombasa",-4.0500,39.6667],
["Kisumu",-0.1000,34.7500],
["Nakuru",-0.2833,36.0667],
["Lodwar",3.1167,35.6000
],

]
for c in coords:
    x = int(ar.shape[1]*lerp(-5.94999981, 6.05000019,c[1]))
    
    y = int(ar.shape[2]*lerp(32.04999924, 43.04999924,c[2]))
    
    liters_per_day = [ar[i][x][y] for i in range(12)]
    print(liters_per_day)
    
    
    # create the plot
    plt.plot(months, liters_per_day,linestyle='--', marker='o',label = c[0],linewidth=6,markersize=20)

# add axis labels

plt.legend()
plt.xlabel("Months")
plt.ylabel("Liters per Day")

plt.grid(True)




plt.show()
#fig2.show()

